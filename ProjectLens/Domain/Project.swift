import Foundation

enum ProjectStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case planned, active, completed, archived
    var id: Self { self }
    var title: String { rawValue.capitalized }
}

struct LedgerProject: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let name: String
    let description: String
    let status: ProjectStatus
    let startDate: Date?
    let endDate: Date?
    let currency: LedgerCurrency
    let budget: Decimal?

    init(id: UUID = UUID(), name: String, description: String = "", status: ProjectStatus = .active,
         startDate: Date? = nil, endDate: Date? = nil, currency: LedgerCurrency,
         budgetText: String = "", locale: Locale = .current) throws {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty && name.count <= 120 else { throw LedgerError.invalidProject }
        guard description.count <= 2_000 else { throw LedgerError.invalidProjectDetails }
        guard [startDate, endDate].compactMap({ $0 }).allSatisfy({ $0.timeIntervalSinceReferenceDate.isFinite }) else {
            throw LedgerError.invalidProjectDates
        }
        if let startDate, let endDate, startDate > endDate { throw LedgerError.invalidProjectDates }
        self.id = id
        self.name = name
        self.description = description
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.currency = currency
        do {
            self.budget = budgetText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil :
                try LedgerAmount.parse(budgetText, currency: currency, locale: locale, allowZero: true)
        } catch LedgerError.invalidAmount { throw LedgerError.invalidBudget }
    }

    func withStatus(_ status: ProjectStatus) throws -> LedgerProject {
        try LedgerProject(id: id, name: name, description: description, status: status,
                          startDate: startDate, endDate: endDate, currency: currency,
                          budgetText: budget.map(LedgerAmount.canonical) ?? "",
                          locale: Locale(identifier: "en_US_POSIX"))
    }

    private enum CodingKeys: String, CodingKey { case id, name, description, status, startDate, endDate, currency, budget }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(id: c.decode(UUID.self, forKey: .id), name: c.decode(String.self, forKey: .name),
                      description: c.decode(String.self, forKey: .description), status: c.decode(ProjectStatus.self, forKey: .status),
                      startDate: c.decodeIfPresent(Date.self, forKey: .startDate), endDate: c.decodeIfPresent(Date.self, forKey: .endDate),
                      currency: c.decode(LedgerCurrency.self, forKey: .currency),
                      budgetText: c.decodeIfPresent(String.self, forKey: .budget) ?? "", locale: Locale(identifier: "en_US_POSIX"))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(description, forKey: .description)
        try c.encode(status, forKey: .status)
        try c.encodeIfPresent(startDate, forKey: .startDate)
        try c.encodeIfPresent(endDate, forKey: .endDate)
        try c.encode(currency, forKey: .currency)
        try c.encodeIfPresent(budget.map(LedgerAmount.canonical), forKey: .budget)
    }
}

struct ProjectFinancials: Equatable, Sendable {
    let revenue: Decimal
    let expenses: Decimal
    let profit: Decimal
    let remainingBudget: Decimal?
    let transactionCount: Int

    static func calculate(project: LedgerProject, transactions: [LedgerTransaction]) throws -> ProjectFinancials {
        let linked = transactions.filter { $0.projectID == project.id }
        guard linked.allSatisfy({ $0.currency == project.currency }) else { throw LedgerError.currencyMismatch }
        let totals = try LedgerTotals.calculate(linked)[project.currency] ?? LedgerTotals()
        return ProjectFinancials(revenue: totals.income, expenses: totals.expenses, profit: totals.net,
                                 remainingBudget: try project.budget.map { try LedgerAmount.add($0, -totals.expenses) },
                                 transactionCount: linked.count)
    }
}

/// Projects and transactions are one validated snapshot and one atomic write.
struct LedgerSnapshot: Equatable, Sendable {
    var transactions: [LedgerTransaction] = []
    var projects: [LedgerProject] = []

    func validate() throws {
        guard Set(transactions.map(\.id)).count == transactions.count,
              Set(projects.map(\.id)).count == projects.count else { throw LedgerError.invalidFile }
        let byID = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
        for transaction in transactions {
            if let id = transaction.projectID {
                guard let project = byID[id] else { throw LedgerError.projectMissing }
                guard project.currency == transaction.currency else { throw LedgerError.currencyMismatch }
            }
        }
        _ = try LedgerTotals.calculate(transactions)
        for project in projects { _ = try ProjectFinancials.calculate(project: project, transactions: transactions) }
    }
}
