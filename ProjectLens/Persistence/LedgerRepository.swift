import Foundation

/// One actor owns the app's versioned local ledger; writes replace the file atomically.
actor LedgerRepository {
    static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "Koshvya/ledger-v1.json")
    }
    private let url: URL
    init(url: URL) { self.url = url }

    private struct Version: Decodable { let version: Int }

    private struct Document: Codable {
        let version: Int
        let transactions: [LedgerTransaction]
    }

    func read() throws -> [LedgerTransaction] {
        let data: Data
        do { data = try Data(contentsOf: url) }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile { return [] }
        do {
            let decoder = JSONDecoder()
            guard try decoder.decode(Version.self, from: data).version == 1 else { throw LedgerError.unsupportedVersion }
            let document = try decoder.decode(Document.self, from: data)
            guard Set(document.transactions.map(\.id)).count == document.transactions.count else {
                throw LedgerError.invalidFile
            }
            return document.transactions
        } catch let error as LedgerError { throw error }
        catch { throw LedgerError.invalidFile }
    }

    func create(_ transaction: LedgerTransaction) throws -> [LedgerTransaction] {
        var records = try read()
        guard !records.contains(where: { $0.id == transaction.id }) else { throw LedgerError.duplicate }
        records.append(transaction)
        try write(records)
        return records
    }

    func update(_ transaction: LedgerTransaction) throws -> [LedgerTransaction] {
        var records = try read()
        guard let index = records.firstIndex(where: { $0.id == transaction.id }) else { throw LedgerError.missing }
        records[index] = transaction
        try write(records)
        return records
    }

    func delete(id: UUID) throws -> [LedgerTransaction] {
        var records = try read()
        guard let index = records.firstIndex(where: { $0.id == id }) else { throw LedgerError.missing }
        records.remove(at: index)
        try write(records)
        return records
    }

    private func write(_ records: [LedgerTransaction]) throws {
        _ = try LedgerTotals.calculate(records)
        let directory = url.deletingLastPathComponent()
        #if os(iOS)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.protectionKey: FileProtectionType.complete])
        let options: Data.WritingOptions = [.atomic, .completeFileProtection]
        #else
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let options: Data.WritingOptions = [.atomic]
        #endif
        let data = try JSONEncoder().encode(Document(version: 1, transactions: records))
        try data.write(to: url, options: options)
    }
}
