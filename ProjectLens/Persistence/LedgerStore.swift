import Foundation
import Combine

@MainActor
final class LedgerStore: ObservableObject {
    @Published private(set) var transactions: [LedgerTransaction] = []
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
        let records = try await (editing ? repository.update(record) : repository.create(record))
        try apply(records)
    }

    func delete(_ record: LedgerTransaction) async throws {
        guard hasLoaded && !isLoading else { throw LedgerError.unavailable }
        guard !isSaving else { throw LedgerError.busy }
        isSaving = true
        defer { isSaving = false }
        try apply(await repository.delete(id: record.id))
    }

    private func apply(_ records: [LedgerTransaction]) throws {
        let totals = try LedgerTotals.calculate(records)
        self.transactions = records.sorted {
            $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date > $1.date
        }
        self.totals = totals
    }
}
