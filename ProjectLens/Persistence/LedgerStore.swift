import Foundation
import Combine

@MainActor
final class LedgerStore: ObservableObject {
    @Published private(set) var transactions: [LedgerTransaction] = []
    @Published private(set) var projects: [LedgerProject] = []
    @Published private(set) var projectFinancials: [UUID: ProjectFinancials] = [:]
    @Published private(set) var totals: [LedgerCurrency: LedgerTotals] = [:]
    @Published private(set) var isLoading = true
    @Published private(set) var hasLoaded = false
    @Published private(set) var isSaving = false
    @Published private(set) var loadError: String?
    private var reading = false
    private let repository: LedgerRepository

    init(repository: LedgerRepository) { self.repository = repository }

    func load() async {
        guard !isSaving && !reading else { return }
        reading = true
        isLoading = true
        defer { isLoading = false; reading = false }
        do {
            try apply(await repository.read())
            hasLoaded = true
            loadError = nil
        } catch {
            hasLoaded = false
            loadError = (error as? LedgerError)?.errorDescription ?? "Could not open your local ledger. Unlock your device and retry. Your file has not been changed."
        }
    }

    func save(_ record: LedgerTransaction, editing: Bool) async throws {
        guard hasLoaded && !isLoading else { throw LedgerError.unavailable }
        guard !isSaving else { throw LedgerError.busy }
        isSaving = true
        defer { isSaving = false }
        let snapshot = try await (editing ? repository.update(record) : repository.create(record))
        try apply(snapshot)
    }

    func delete(_ record: LedgerTransaction) async throws {
        guard hasLoaded && !isLoading else { throw LedgerError.unavailable }
        guard !isSaving else { throw LedgerError.busy }
        isSaving = true
        defer { isSaving = false }
        try apply(await repository.delete(id: record.id))
    }

    func saveProject(_ project: LedgerProject, editing: Bool) async throws {
        guard hasLoaded && !isLoading else { throw LedgerError.unavailable }
        guard !isSaving else { throw LedgerError.busy }
        isSaving = true
        defer { isSaving = false }
        try apply(await repository.saveProject(project, editing: editing))
    }

    func deleteProject(_ project: LedgerProject) async throws {
        guard hasLoaded && !isLoading else { throw LedgerError.unavailable }
        guard !isSaving else { throw LedgerError.busy }
        isSaving = true
        defer { isSaving = false }
        try apply(await repository.deleteProject(id: project.id))
    }

    func project(id: UUID?) -> LedgerProject? {
        projects.first { $0.id == id }
    }

    private func apply(_ snapshot: LedgerSnapshot) throws {
        let totals = try LedgerTotals.calculate(snapshot.transactions)
        let financials = try Dictionary(uniqueKeysWithValues: snapshot.projects.map {
            ($0.id, try ProjectFinancials.calculate(project: $0, transactions: snapshot.transactions))
        })
        self.transactions = snapshot.transactions.sorted {
            $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date > $1.date
        }
        self.projects = snapshot.projects.sorted {
            if ($0.status == .archived) != ($1.status == .archived) { return $0.status != .archived }
            if $0.name != $1.name { return $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return $0.id.uuidString < $1.id.uuidString
        }
        self.projectFinancials = financials
        self.totals = totals
    }
}
