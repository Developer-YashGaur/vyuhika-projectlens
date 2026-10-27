import XCTest
@testable import ProjectLens

final class ProjectFinanceTests: XCTestCase {
    private let posix = Locale(identifier: "en_US_POSIX")

    private func url() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return directory.appendingPathComponent("ledger.json")
    }

    private func project(_ name: String = "Orbit", id: UUID = UUID(), currency: LedgerCurrency = .INR,
                         budget: String = "100") throws -> LedgerProject {
        try LedgerProject(id: id, name: name, description: "Client work", currency: currency, budgetText: budget, locale: posix)
    }

    private func transaction(_ amount: String, project: LedgerProject? = nil, kind: TransactionKind = .expense,
                             currency: LedgerCurrency? = nil, id: UUID = UUID()) throws -> LedgerTransaction {
        try LedgerTransaction(id: id, kind: kind, amountText: amount, currency: currency ?? project?.currency ?? .INR,
                              category: "Tools", date: Date(timeIntervalSince1970: 1_700_000_000), notes: "Keep this note",
                              projectID: project?.id, locale: posix)
    }

    func testProjectCRUDArchiveAndReload() async throws {
        let file = try url()
        let repository = LedgerRepository(url: file)
        let original = try project()
        let created = try await repository.saveProject(original, editing: false)
        XCTAssertEqual(created.projects, [original])
        let edited = try LedgerProject(id: original.id, name: "Renamed", description: "Changed", status: .completed,
                                       startDate: Date(timeIntervalSince1970: 100), endDate: Date(timeIntervalSince1970: 200),
                                       currency: .USD, budgetText: "12.34", locale: posix)
        _ = try await repository.saveProject(edited, editing: true)
        let archived = try edited.withStatus(.archived)
        _ = try await repository.saveProject(archived, editing: true)
        let reloaded = try await LedgerRepository(url: file).read()
        XCTAssertEqual(reloaded.projects, [archived])
        _ = try await repository.saveProject(archived.withStatus(.active), editing: true)
        let removed = try await repository.deleteProject(id: original.id)
        XCTAssertTrue(removed.projects.isEmpty)
        let afterDelete = try await repository.read()
        XCTAssertTrue(afterDelete.projects.isEmpty)
    }

    func testDuplicateAndMissingProjectMutationsDoNotWrite() async throws {
        let file = try url()
        let repository = LedgerRepository(url: file)
        let original = try project()
        _ = try await repository.saveProject(original, editing: false)
        let before = try Data(contentsOf: file)
        do { _ = try await repository.saveProject(original, editing: false); XCTFail("Duplicate accepted") }
        catch { XCTAssertEqual(error as? LedgerError, .duplicate) }
        do { _ = try await repository.saveProject(project(), editing: true); XCTFail("Missing edit accepted") }
        catch { XCTAssertEqual(error as? LedgerError, .missing) }
        do { _ = try await repository.deleteProject(id: UUID()); XCTFail("Missing delete accepted") }
        catch { XCTAssertEqual(error as? LedgerError, .missing) }
        XCTAssertEqual(try Data(contentsOf: file), before)
    }

    func testProjectValidationAndExactBudgetEncoding() throws {
        XCTAssertThrowsError(try project("  "))
        XCTAssertThrowsError(try project(String(repeating: "a", count: 121)))
        XCTAssertThrowsError(try LedgerProject(name: "Orbit", description: String(repeating: "a", count: 2_001), currency: .INR))
        XCTAssertThrowsError(try project(budget: "-1"))
        XCTAssertThrowsError(try project(budget: "1.001"))
        XCTAssertThrowsError(try project(budget: "1234567890123"))
        XCTAssertThrowsError(try LedgerProject(name: "Orbit", startDate: Date(timeIntervalSince1970: 200),
                                              endDate: Date(timeIntervalSince1970: 100), currency: .INR))
        XCTAssertThrowsError(try LedgerProject(name: "Orbit", endDate: Date(timeIntervalSinceReferenceDate: .infinity), currency: .INR))
        XCTAssertEqual(try project("  Trimmed  ", budget: "0").name, "Trimmed")
        XCTAssertEqual(try project(budget: "0").budget, 0)
        XCTAssertNil(try project(budget: "").budget)
        let value = try project(currency: .KWD, budget: "999999999999.999")
        let data = try JSONEncoder().encode(value)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["budget"] as? String, "999999999999.999")
        XCTAssertEqual(try JSONDecoder().decode(LedgerProject.self, from: data), value)
        XCTAssertThrowsError(try project(currency: .JPY, budget: "1.1"))
        XCTAssertEqual(try LedgerProject(name: "Orbit", currency: .EUR, budgetText: "12,34", locale: Locale(identifier: "de_DE")).budget,
                       Decimal(string: "12.34"))
    }

    func testLinkRelinkUnlinkAndRenameUseStableIdentifiers() async throws {
        let file = try url()
        let repository = LedgerRepository(url: file)
        let first = try project("First"), second = try project("Second")
        _ = try await repository.saveProject(first, editing: false)
        _ = try await repository.saveProject(second, editing: false)
        let original = try transaction("12.34")
        _ = try await repository.create(original)
        let linked = try original.assigning(projectID: first.id)
        _ = try await repository.update(linked)
        let renamed = try project("Renamed", id: first.id)
        let afterRename = try await repository.saveProject(renamed, editing: true)
        XCTAssertEqual(afterRename.transactions.first?.projectID, first.id)
        _ = try await repository.update(linked.assigning(projectID: second.id))
        let relinked = try await LedgerRepository(url: file).read()
        XCTAssertEqual(relinked.transactions.first?.projectID, second.id)
        let unlinked = try await repository.update(original)
        XCTAssertEqual(unlinked.transactions, [original])
        XCTAssertEqual(try LedgerTotals.calculate(unlinked.transactions)[.INR]?.expenses, Decimal(string: "12.34"))
    }

    func testProjectDeletionKeepsFinancialHistoryAndUnlinksAtomically() async throws {
        let file = try url()
        let repository = LedgerRepository(url: file)
        let first = try project(), second = try project("Second")
        _ = try await repository.saveProject(first, editing: false)
        _ = try await repository.saveProject(second, editing: false)
        let expense = try transaction("12.34", project: first)
        let income = try transaction("50", project: first, kind: .income)
        let other = try transaction("1", project: second)
        for record in [expense, income, other] { _ = try await repository.create(record) }
        let before = try LedgerTotals.calculate([expense, income, other])
        let snapshot = try await repository.deleteProject(id: first.id)
        XCTAssertEqual(snapshot.projects, [second])
        XCTAssertEqual(snapshot.transactions, [try expense.assigning(projectID: nil), try income.assigning(projectID: nil), other])
        XCTAssertEqual(try LedgerTotals.calculate(snapshot.transactions), before)
        let reloaded = try await LedgerRepository(url: file).read()
        XCTAssertEqual(reloaded, snapshot)
    }

    func testCurrencyAndOrphanGuardsPreserveFileOnCreateAndEdit() async throws {
        let file = try url()
        let repository = LedgerRepository(url: file)
        let value = try project()
        _ = try await repository.saveProject(value, editing: false)
        let original = try transaction("1", project: value)
        _ = try await repository.create(original)
        let before = try Data(contentsOf: file)
        do { _ = try await repository.create(transaction("1", project: value, currency: .USD)); XCTFail("Mixed currency accepted") }
        catch { XCTAssertEqual(error as? LedgerError, .currencyMismatch) }
        do { _ = try await repository.update(transaction("1", project: value, currency: .USD, id: original.id)); XCTFail("Mixed edit accepted") }
        catch { XCTAssertEqual(error as? LedgerError, .currencyMismatch) }
        do { _ = try await repository.saveProject(project(id: value.id, currency: .USD), editing: true); XCTFail("Currency changed with links") }
        catch { XCTAssertEqual(error as? LedgerError, .currencyMismatch) }
        do { _ = try await repository.create(transaction("1").assigning(projectID: UUID())); XCTFail("Orphan accepted") }
        catch { XCTAssertEqual(error as? LedgerError, .projectMissing) }
        do { _ = try await repository.update(original.assigning(projectID: UUID())); XCTFail("Orphan edit accepted") }
        catch { XCTAssertEqual(error as? LedgerError, .projectMissing) }
        XCTAssertEqual(try Data(contentsOf: file), before)
        _ = try await repository.update(original.assigning(projectID: nil))
        let changed = try await repository.saveProject(project(id: value.id, currency: .USD), editing: true)
        XCTAssertEqual(changed.projects.first?.currency, .USD)
    }

    func testExactFinancialsBudgetConsumptionIsIndependentOfProfit() throws {
        let value = try project(currency: .KWD, budget: "0.300")
        let other = try project("Other", currency: .USD)
        let records = [try transaction("0.100", project: value, kind: .income),
                       try transaction("0.200", project: value, kind: .income),
                       try transaction("0.070", project: value), try transaction("99", project: other)]
        let result = try ProjectFinancials.calculate(project: value, transactions: records)
        XCTAssertEqual(result.revenue, Decimal(string: "0.3"))
        XCTAssertEqual(result.expenses, Decimal(string: "0.07"))
        XCTAssertEqual(result.profit, Decimal(string: "0.23"))
        XCTAssertEqual(result.remainingBudget, Decimal(string: "0.23"))
        XCTAssertEqual(result.transactionCount, 3)
        let overspent = try ProjectFinancials.calculate(project: value, transactions: [try transaction("0.400", project: value)])
        XCTAssertEqual(overspent.remainingBudget, Decimal(string: "-0.1"))
        XCTAssertEqual(overspent.profit, Decimal(string: "-0.4"))
        let profitableOverBudget = try ProjectFinancials.calculate(project: value, transactions: [
            transaction("1", project: value, kind: .income), transaction("0.400", project: value)
        ])
        XCTAssertEqual(profitableOverBudget.profit, Decimal(string: "0.6"))
        XCTAssertEqual(profitableOverBudget.remainingBudget, Decimal(string: "-0.1"))
        let noBudget = try project(id: value.id, currency: .KWD, budget: "")
        XCTAssertNil(try ProjectFinancials.calculate(project: noBudget, transactions: records).remainingBudget)
        let empty = try ProjectFinancials.calculate(project: value, transactions: [])
        XCTAssertEqual(empty.revenue, 0); XCTAssertEqual(empty.profit, 0); XCTAssertEqual(empty.remainingBudget, value.budget)
        XCTAssertThrowsError(try ProjectFinancials.calculate(project: value, transactions: [transaction("1", project: value, currency: .USD)]))
        let incomeOnly = try ProjectFinancials.calculate(project: value, transactions: [transaction("10", project: value, kind: .income)])
        XCTAssertEqual(incomeOnly.remainingBudget, value.budget)
        XCTAssertEqual(incomeOnly.profit, 10)
    }

    private func legacyData(_ records: [(LedgerTransaction, String?)]) throws -> Data {
        let values = try records.map { record, label -> [String: Any] in
            var value = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(record)) as? [String: Any])
            if let label { value["project"] = label }
            return value
        }
        return try JSONSerialization.data(withJSONObject: ["version": 1, "transactions": values], options: [.sortedKeys])
    }

    func testV1MigrationPreservesRecordsSeparatesCurrenciesAndPersistsStableLinks() async throws {
        let file = try url()
        let a = try transaction("12.34"), b = try transaction("20", kind: .income)
        let c = try transaction("3", currency: .USD), d = try transaction("4")
        let original = try legacyData([(a, " Orbit "), (b, "Orbit"), (c, "Orbit"), (d, nil)])
        try original.write(to: file)
        let repository = LedgerRepository(url: file)
        let migrated = try await repository.read()
        XCTAssertEqual(migrated.projects.count, 2)
        XCTAssertEqual(migrated.transactions.map(\.id), [a.id, b.id, c.id, d.id])
        XCTAssertEqual(migrated.transactions[0].projectID, migrated.transactions[1].projectID)
        XCTAssertNotEqual(migrated.transactions[0].projectID, migrated.transactions[2].projectID)
        XCTAssertNil(migrated.transactions[3].projectID)
        XCTAssertEqual(try LedgerTotals.calculate(migrated.transactions), try LedgerTotals.calculate([a, b, c, d]))
        for (before, after) in zip([a, b, c, d], migrated.transactions) {
            XCTAssertEqual(try after.assigning(projectID: nil), before)
        }
        XCTAssertTrue(migrated.projects.allSatisfy { $0.budget == nil && $0.name == "Orbit" })
        XCTAssertEqual(try Data(contentsOf: file.appendingPathExtension("v1-backup")), original)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        XCTAssertEqual(json["version"] as? Int, 2)
        let transactions = try XCTUnwrap(json["transactions"] as? [[String: Any]])
        XCTAssertNil(transactions[0]["project"])
        XCTAssertNotNil(transactions[0]["projectID"])
        let reloaded = try await LedgerRepository(url: file).read()
        XCTAssertEqual(reloaded, migrated)
    }

    func testMigrationRefusesCorruptOrDuplicateV1WithoutWriting() async throws {
        let file = try url()
        let record = try transaction("1")
        for data in [try legacyData([(record, "Orbit"), (record, "Orbit")]),
                     try legacyData([(record, String(repeating: "a", count: 121))]),
                     Data(#"{"version":1,"transactions":[{"amount":"broken"}]}"#.utf8)] {
            try data.write(to: file)
            do { _ = try await LedgerRepository(url: file).read(); XCTFail("Invalid migration accepted") }
            catch { }
            XCTAssertEqual(try Data(contentsOf: file), data)
            XCTAssertFalse(FileManager.default.fileExists(atPath: file.appendingPathExtension("v1-backup").path))
        }
    }

    func testMigrationBackupFailurePreservesOriginalAndExistingBackup() async throws {
        let file = try url()
        let original = try legacyData([(transaction("1"), "Orbit")])
        try original.write(to: file)
        let backup = file.appendingPathExtension("v1-backup")
        try Data("previous backup".utf8).write(to: backup)
        do { _ = try await LedgerRepository(url: file).read(); XCTFail("Conflicting backup replaced") }
        catch { XCTAssertEqual(error as? LedgerError, .invalidFile) }
        XCTAssertEqual(try Data(contentsOf: file), original)
        XCTAssertEqual(try String(contentsOf: backup, encoding: .utf8), "previous backup")
    }

    func testV2RejectsDanglingLinksDuplicateProjectsAndMismatchedCurrencies() async throws {
        let file = try url()
        let value = try project()
        let encoder = JSONEncoder()
        let projectJSON = try JSONSerialization.jsonObject(with: encoder.encode(value))
        let orphan = try transaction("1").assigning(projectID: UUID())
        let mismatch = try transaction("1", project: value, currency: .USD)
        for (projects, records) in [([projectJSON, projectJSON], [LedgerTransaction]()),
                                    ([projectJSON], [orphan]), ([projectJSON], [mismatch])] {
            let txJSON = try records.map { try JSONSerialization.jsonObject(with: encoder.encode($0)) }
            let data = try JSONSerialization.data(withJSONObject: ["version": 2, "projects": projects, "transactions": txJSON])
            try data.write(to: file)
            do { _ = try await LedgerRepository(url: file).saveProject(project("New"), editing: false); XCTFail("Invalid v2 overwritten") }
            catch { }
            XCTAssertEqual(try Data(contentsOf: file), data)
        }
    }

    func testConcurrentProjectAndTransactionMutationsDoNotLoseData() async throws {
        let repository = LedgerRepository(url: try url())
        let value = try project()
        let record = try transaction("1")
        async let projectWrite = repository.saveProject(value, editing: false)
        async let transactionWrite = repository.create(record)
        _ = try await (projectWrite, transactionWrite)
        let snapshot = try await repository.read()
        XCTAssertEqual(snapshot.projects, [value]); XCTAssertEqual(snapshot.transactions, [record])
    }

    @MainActor
    func testProjectSaveDiskFailureDoesNotPublishDraft() async throws {
        let file = try url()
        let blocked = file.deletingLastPathComponent().appendingPathComponent("blocked")
        let store = LedgerStore(repository: LedgerRepository(url: blocked.appendingPathComponent("ledger.json")))
        await store.load()
        try Data("not a directory".utf8).write(to: blocked)
        do { try await store.saveProject(project(), editing: false); XCTFail("Write unexpectedly succeeded") }
        catch { }
        XCTAssertTrue(store.projects.isEmpty)
        XCTAssertTrue(store.projectFinancials.isEmpty)
        XCTAssertFalse(store.isSaving)
        XCTAssertEqual(try String(contentsOf: blocked, encoding: .utf8), "not a directory")
    }

    @MainActor
    func testLinkedTransactionEditDeleteAndArchivedEntriesRecalculateProject() async throws {
        let store = LedgerStore(repository: LedgerRepository(url: try url()))
        await store.load()
        let value = try project()
        try await store.saveProject(value, editing: false)
        let original = try transaction("10", project: value)
        try await store.save(original, editing: false)
        let edited = try transaction("25", project: value, kind: .income, id: original.id)
        try await store.save(edited, editing: true)
        XCTAssertEqual(store.projectFinancials[value.id]?.expenses, 0)
        XCTAssertEqual(store.projectFinancials[value.id]?.profit, 25)
        XCTAssertEqual(store.projectFinancials[value.id]?.remainingBudget, 100)
        try await store.saveProject(value.withStatus(.archived), editing: true)
        let expense = try transaction("120", project: value)
        try await store.save(expense, editing: false)
        XCTAssertEqual(store.projectFinancials[value.id]?.remainingBudget, -20)
        XCTAssertEqual(store.projectFinancials[value.id]?.profit, -95)
        try await store.delete(edited)
        XCTAssertEqual(store.projectFinancials[value.id]?.revenue, 0)
        XCTAssertEqual(store.projectFinancials[value.id]?.profit, -120)
        try await store.delete(expense)
        XCTAssertEqual(store.projectFinancials[value.id]?.transactionCount, 0)
        XCTAssertEqual(store.projectFinancials[value.id]?.remainingBudget, 100)
    }

    @MainActor
    func testStorePublishesProjectFinancialsOnlyAfterSuccessfulWrites() async throws {
        let file = try url()
        let store = LedgerStore(repository: LedgerRepository(url: file))
        let value = try project()
        do { try await store.saveProject(value, editing: false); XCTFail("Saved before load") }
        catch { XCTAssertEqual(error as? LedgerError, .unavailable) }
        await store.load()
        try await store.saveProject(value, editing: false)
        let record = try transaction("12.34", project: value)
        try await store.save(record, editing: false)
        XCTAssertEqual(store.projectFinancials[value.id]?.remainingBudget, Decimal(string: "87.66"))
        do { try await store.saveProject(project(id: value.id, currency: .USD), editing: true); XCTFail("Invalid save accepted") }
        catch { XCTAssertEqual(store.projects, [value]); XCTAssertFalse(store.isSaving) }
        try await store.saveProject(value.withStatus(.archived), editing: true)
        XCTAssertEqual(store.projects.first?.status, .archived)
        XCTAssertEqual(store.projectFinancials[value.id]?.expenses, record.amount)
        try await store.deleteProject(value)
        XCTAssertTrue(store.projects.isEmpty); XCTAssertTrue(store.projectFinancials.isEmpty)
        XCTAssertNil(store.transactions.first?.projectID)
        XCTAssertEqual(store.totals[.INR]?.expenses, record.amount)
        await store.load()
        XCTAssertTrue(store.hasLoaded); XCTAssertTrue(store.projects.isEmpty)
    }
}
