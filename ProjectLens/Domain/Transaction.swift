import Foundation

enum TransactionKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case expense, income
    var id: Self { self }
    var title: String { self == .income ? "Income" : "Expense" }
}

/// Explicitly supported currencies; no currency conversion or implicit rounding.
enum LedgerCurrency: String, Codable, CaseIterable, Identifiable, Sendable {
    case USD, EUR, GBP, INR, JPY, KWD
    var id: Self { self }
    var fractionDigits: Int {
        switch self {
        case .JPY: 0
        case .KWD: 3
        default: 2
        }
    }
    func formatted(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: rawValue).precision(.fractionLength(fractionDigits)))
    }
}

enum LedgerError: LocalizedError, Equatable {
    case invalidAmount, invalidPrecision, invalidCategory, invalidNotes, invalidProject, invalidDate
    case duplicate, missing, unsupportedVersion, invalidFile, unavailable, busy, arithmetic
    case invalidProjectDetails, invalidProjectDates, invalidBudget, projectMissing, currencyMismatch
    var errorDescription: String? {
        switch self {
        case .invalidAmount: "Enter a positive amount with at most 12 whole-number digits. Use a decimal separator, without grouping or currency symbols."
        case .invalidPrecision: "The amount has more decimal places than this currency supports."
        case .invalidCategory: "Enter a category of 1–80 characters."
        case .invalidNotes: "Notes must be 2,000 characters or fewer."
        case .invalidProject: "Enter a project name of 1–120 characters."
        case .invalidBudget: "Enter a budget of zero or more with at most 12 whole-number digits, without grouping or currency symbols. Leave blank for no budget."
        case .invalidProjectDetails: "Project description must be 2,000 characters or fewer."
        case .invalidProjectDates: "Choose valid project dates. End date must be on or after start date."
        case .projectMissing: "This project no longer exists. Choose another project or unlink the transaction."
        case .currencyMismatch: "A linked transaction must use its project's currency. Unlink or choose a matching project before changing currency. A project's currency cannot change while transactions are linked."
        case .invalidDate: "Choose a valid transaction date."
        case .duplicate: "This record already exists."
        case .missing: "This record no longer exists. Reload and try again."
        case .unsupportedVersion: "This ledger was created by a newer app version. Update Koshvya before opening it."
        case .invalidFile: "The local ledger could not be read safely. Your file has not been changed."
        case .unavailable: "Reload your local ledger before making changes."
        case .busy: "Another change is being saved. Please try again."
        case .arithmetic: "These amounts could not be totaled exactly."
        }
    }
}

enum LedgerAmount {
    static func parse(_ input: String, currency: LedgerCurrency, locale: Locale = .current, allowZero: Bool = false) throws -> Decimal {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if let separator = locale.decimalSeparator, separator != "." {
            // Accept the local separator or canonical dot, but never grouping.
            if text.contains(separator) && text.contains(".") { throw LedgerError.invalidAmount }
            text = text.replacingOccurrences(of: separator, with: ".")
        }
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2, let whole = parts.first, !whole.isEmpty, whole.count <= 12,
              text.allSatisfy({ ("0"..."9").contains(String($0)) || $0 == "." }),
              parts.count == 1 || !parts[1].isEmpty,
              let value = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")),
              !value.isNaN, (allowZero ? value >= 0 : value > 0) else { throw LedgerError.invalidAmount }
        guard parts.count == 1 || parts[1].count <= currency.fractionDigits else {
            throw LedgerError.invalidPrecision
        }
        return value
    }

    static func canonical(_ value: Decimal) -> String {
        var value = value
        return NSDecimalString(&value, Locale(identifier: "en_US_POSIX"))
    }

    static func add(_ lhs: Decimal, _ rhs: Decimal) throws -> Decimal {
        var lhs = lhs, rhs = rhs, result = Decimal()
        guard NSDecimalAdd(&result, &lhs, &rhs, .plain) == .noError else { throw LedgerError.arithmetic }
        return result
    }
}

struct LedgerTransaction: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let kind: TransactionKind
    let amount: Decimal
    let currency: LedgerCurrency
    let category: String
    let date: Date
    let notes: String
    let projectID: UUID?

    init(id: UUID = UUID(), kind: TransactionKind, amountText: String, currency: LedgerCurrency,
         category: String, date: Date, notes: String = "", projectID: UUID? = nil, locale: Locale = .current) throws {
        let category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !category.isEmpty && category.count <= 80 else { throw LedgerError.invalidCategory }
        guard notes.count <= 2_000 else { throw LedgerError.invalidNotes }
        guard date.timeIntervalSinceReferenceDate.isFinite else { throw LedgerError.invalidDate }
        self.id = id
        self.kind = kind
        self.amount = try LedgerAmount.parse(amountText, currency: currency, locale: locale)
        self.currency = currency
        self.category = category
        self.date = date
        self.notes = notes
        self.projectID = projectID
    }

    func assigning(projectID: UUID?) throws -> LedgerTransaction {
        try LedgerTransaction(id: id, kind: kind, amountText: LedgerAmount.canonical(amount), currency: currency,
                              category: category, date: date, notes: notes, projectID: projectID,
                              locale: Locale(identifier: "en_US_POSIX"))
    }

    private enum CodingKeys: String, CodingKey { case id, kind, amount, currency, category, date, notes, projectID }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(id: c.decode(UUID.self, forKey: .id), kind: c.decode(TransactionKind.self, forKey: .kind),
                      amountText: c.decode(String.self, forKey: .amount), currency: c.decode(LedgerCurrency.self, forKey: .currency),
                      category: c.decode(String.self, forKey: .category), date: c.decode(Date.self, forKey: .date),
                      notes: c.decode(String.self, forKey: .notes), projectID: c.decodeIfPresent(UUID.self, forKey: .projectID),
                      locale: Locale(identifier: "en_US_POSIX"))
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(kind, forKey: .kind)
        try c.encode(LedgerAmount.canonical(amount), forKey: .amount)
        try c.encode(currency, forKey: .currency)
        try c.encode(category, forKey: .category)
        try c.encode(date, forKey: .date)
        try c.encode(notes, forKey: .notes)
        try c.encodeIfPresent(projectID, forKey: .projectID)
    }
}

struct LedgerTotals: Equatable, Sendable {
    var income: Decimal = 0
    var expenses: Decimal = 0
    var net: Decimal = 0

    static func calculate(_ records: [LedgerTransaction]) throws -> [LedgerCurrency: LedgerTotals] {
        var result: [LedgerCurrency: LedgerTotals] = [:]
        for record in records {
            var total = result[record.currency, default: LedgerTotals()]
            if record.kind == .income { total.income = try LedgerAmount.add(total.income, record.amount) }
            else { total.expenses = try LedgerAmount.add(total.expenses, record.amount) }
            total.net = try LedgerAmount.add(total.income, -total.expenses)
            result[record.currency] = total
        }
        return result
    }
}
