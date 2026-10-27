import Foundation

/// One actor owns projects and transactions. A mutation replaces the complete document atomically.
actor LedgerRepository {
    static var defaultURL: URL {
        // Keep the original path so installed ledgers are found; the document has its own schema version.
        URL.applicationSupportDirectory.appending(path: "Koshvya/ledger-v1.json")
    }
    private let url: URL
    init(url: URL) { self.url = url }

    private struct Version: Decodable { let version: Int }
    private struct Document: Codable {
        let version: Int
        let transactions: [LedgerTransaction]
        let projects: [LedgerProject]
    }
    private struct LegacyTransaction: Decodable {
        let record: LedgerTransaction
        let label: String
        private enum CodingKeys: String, CodingKey { case project }
        init(from decoder: Decoder) throws {
            record = try LedgerTransaction(from: decoder)
            let c = try decoder.container(keyedBy: CodingKeys.self)
            label = try c.decodeIfPresent(String.self, forKey: .project)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard label.count <= 120, record.projectID == nil else { throw LedgerError.invalidFile }
        }
    }
    private struct LegacyDocument: Decodable { let transactions: [LegacyTransaction] }
    private struct LegacyProjectKey: Hashable { let name: String; let currency: LedgerCurrency }

    func read() throws -> LedgerSnapshot {
        let data: Data
        do { data = try Data(contentsOf: url) }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile { return LedgerSnapshot() }
        do {
            let decoder = JSONDecoder()
            let version = try decoder.decode(Version.self, from: data).version
            if version == 1 {
                let legacy = try decoder.decode(LegacyDocument.self, from: data)
                var snapshot = LedgerSnapshot()
                var identifiers: [LegacyProjectKey: UUID] = [:]
                for entry in legacy.transactions {
                    var projectID: UUID?
                    if !entry.label.isEmpty {
                        let key = LegacyProjectKey(name: entry.label, currency: entry.record.currency)
                        if let existing = identifiers[key] { projectID = existing }
                        else {
                            let project = try LedgerProject(name: entry.label, currency: entry.record.currency)
                            identifiers[key] = project.id
                            snapshot.projects.append(project)
                            projectID = project.id
                        }
                    }
                    snapshot.transactions.append(try entry.record.assigning(projectID: projectID))
                }
                try snapshot.validate()
                // Validate everything before touching either file. Never replace an earlier backup.
                let backup = url.appendingPathExtension("v1-backup")
                if FileManager.default.fileExists(atPath: backup.path) {
                    guard try Data(contentsOf: backup) == data else { throw LedgerError.invalidFile }
                } else { try persist(data, to: backup) }
                try write(snapshot)
                return snapshot
            }
            guard version == 2 else { throw LedgerError.unsupportedVersion }
            let document = try decoder.decode(Document.self, from: data)
            let snapshot = LedgerSnapshot(transactions: document.transactions, projects: document.projects)
            try snapshot.validate()
            return snapshot
        } catch let error as LedgerError { throw error }
        catch let error as CocoaError { throw error }
        catch { throw LedgerError.invalidFile }
    }

    func create(_ transaction: LedgerTransaction) throws -> LedgerSnapshot {
        try mutate { snapshot in
            guard !snapshot.transactions.contains(where: { $0.id == transaction.id }) else { throw LedgerError.duplicate }
            snapshot.transactions.append(transaction)
        }
    }

    func update(_ transaction: LedgerTransaction) throws -> LedgerSnapshot {
        try mutate { snapshot in
            guard let index = snapshot.transactions.firstIndex(where: { $0.id == transaction.id }) else { throw LedgerError.missing }
            snapshot.transactions[index] = transaction
        }
    }

    func delete(id: UUID) throws -> LedgerSnapshot {
        try mutate { snapshot in
            guard let index = snapshot.transactions.firstIndex(where: { $0.id == id }) else { throw LedgerError.missing }
            snapshot.transactions.remove(at: index)
        }
    }

    func saveProject(_ project: LedgerProject, editing: Bool) throws -> LedgerSnapshot {
        try mutate { snapshot in
            if editing {
                guard let index = snapshot.projects.firstIndex(where: { $0.id == project.id }) else { throw LedgerError.missing }
                snapshot.projects[index] = project
            } else {
                guard !snapshot.projects.contains(where: { $0.id == project.id }) else { throw LedgerError.duplicate }
                snapshot.projects.append(project)
            }
        }
    }

    /// Unlink, never delete financial history. Both changes commit in the same atomic document.
    func deleteProject(id: UUID) throws -> LedgerSnapshot {
        try mutate { snapshot in
            guard let index = snapshot.projects.firstIndex(where: { $0.id == id }) else { throw LedgerError.missing }
            snapshot.projects.remove(at: index)
            snapshot.transactions = try snapshot.transactions.map {
                $0.projectID == id ? try $0.assigning(projectID: nil) : $0
            }
        }
    }

    private func mutate(_ change: (inout LedgerSnapshot) throws -> Void) throws -> LedgerSnapshot {
        var snapshot = try read()
        try change(&snapshot)
        try write(snapshot)
        return snapshot
    }

    private func write(_ snapshot: LedgerSnapshot) throws {
        try snapshot.validate()
        let data = try JSONEncoder().encode(Document(version: 2, transactions: snapshot.transactions, projects: snapshot.projects))
        try persist(data, to: url)
    }

    private func persist(_ data: Data, to destination: URL) throws {
        let directory = destination.deletingLastPathComponent()
        #if os(iOS)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.protectionKey: FileProtectionType.complete])
        let options: Data.WritingOptions = [.atomic, .completeFileProtection]
        #else
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let options: Data.WritingOptions = [.atomic]
        #endif
        try data.write(to: destination, options: options)
    }
}
