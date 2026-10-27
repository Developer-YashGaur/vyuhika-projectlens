import XCTest
@testable import ProjectLens

final class LedgerTests: XCTestCase {
    private let posix = Locale(identifier: "en_US_POSIX")

    private func record(_ amount: String = "12.34", kind: TransactionKind = .expense,
                        currency: LedgerCurrency = .INR, id: UUID = UUID(), category: String = "Tools") throws -> LedgerTransaction {
        try LedgerTransaction(id: id, kind: kind, amountText: amount, currency: currency, category: category,
                              date: Date(timeIntervalSince1970: 1_700_000_000), notes: "Annual tool", locale: posix)
    }

    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    func testCreateUpdateDeleteAndReload() async throws {
        let url = try directory().appendingPathComponent("ledger.json")
        let repository = LedgerRepository(url: url)
        let original = try record()
        let empty = try await repository.read().transactions
        XCTAssertTrue(empty.isEmpty)
        let created = try await repository.create(original).transactions
        XCTAssertEqual(created, [original])
        let reloaded = try await LedgerRepository(url: url).read().transactions
        XCTAssertEqual(reloaded, [original])
        let edited = try record("45.67", kind: .income, currency: .GBP, id: original.id, category: "Client work")
        let updated = try await repository.update(edited).transactions
        XCTAssertEqual(updated, [edited])
        let persisted = try await LedgerRepository(url: url).read().transactions
        XCTAssertEqual(persisted, [edited])
        let removed = try await repository.delete(id: original.id).transactions
        XCTAssertTrue(removed.isEmpty)
        let afterDelete = try await LedgerRepository(url: url).read().transactions
        XCTAssertTrue(afterDelete.isEmpty)
    }

    func testConcurrentCreatesAreSerializedWithoutLostEntries() async throws {
        let repository = LedgerRepository(url: try directory().appendingPathComponent("ledger.json"))
        let first = try record("1.25")
        let second = try record("2.50", kind: .income)
        async let firstWrite = repository.create(first)
        async let secondWrite = repository.create(second)
        _ = try await (firstWrite, secondWrite)
        let records = try await repository.read().transactions
        XCTAssertEqual(Set(records.map(\.id)), Set([first.id, second.id]))
    }

    func testRejectsMalformedAndNonpositiveAmounts() {
        for input in ["", "0", "-1", "+2", "NaN", "Infinity", "1e2", "1,234.56", "1.2.3", ".5", "1.", "1234567890123"] {
            XCTAssertThrowsError(try record(input), input)
        }
    }

    func testCurrencyPrecisionIsExplicit() throws {
        XCTAssertThrowsError(try record("1.001", currency: .USD))
        XCTAssertThrowsError(try record("1.1", currency: .JPY))
        XCTAssertThrowsError(try record("1.0001", currency: .KWD))
        XCTAssertEqual(try record("1.001", currency: .KWD).amount, Decimal(string: "1.001"))
        XCTAssertEqual(try record("1", currency: .JPY).amount, 1)
    }

    func testLocalizedSeparatorWithoutGrouping() throws {
        let locale = Locale(identifier: "de_DE")
        XCTAssertEqual(try LedgerAmount.parse("12,34", currency: .EUR, locale: locale), Decimal(string: "12.34"))
        XCTAssertEqual(try LedgerAmount.parse("12.34", currency: .EUR, locale: locale), Decimal(string: "12.34"))
        XCTAssertThrowsError(try LedgerAmount.parse("1.234,56", currency: .EUR, locale: locale))
    }

    func testValidatesAndNormalizesMetadata() throws {
        XCTAssertThrowsError(try record(category: "   "))
        XCTAssertThrowsError(try record(category: String(repeating: "a", count: 81)))
        let record = try LedgerTransaction(kind: .income, amountText: "2.50", currency: .USD, category: " Work ", date: Date(), locale: posix)
        XCTAssertEqual(record.category, "Work")
        XCTAssertNil(record.projectID)
        XCTAssertThrowsError(try LedgerTransaction(kind: .expense, amountText: "1", currency: .USD, category: "Tools", date: Date(), notes: String(repeating: "a", count: 2_001)))
    }

    func testDecimalEncodingRoundTripsWithoutBinaryFloatingPoint() throws {
        let record = try record("999999999999.999", currency: .KWD)
        let data = try JSONEncoder().encode(record)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["amount"] as? String, "999999999999.999")
        XCTAssertEqual(try JSONDecoder().decode(LedgerTransaction.self, from: data), record)
    }

    func testTotalsAreExactAndNeverCombineCurrencies() throws {
        let records = [try record("0.10", kind: .income, currency: .USD),
                       try record("0.20", kind: .income, currency: .USD),
                       try record("0.07", currency: .USD), try record("20", currency: .INR)]
        let totals = try LedgerTotals.calculate(records)
        XCTAssertEqual(totals[.USD]?.income, Decimal(string: "0.30"))
        XCTAssertEqual(totals[.USD]?.expenses, Decimal(string: "0.07"))
        XCTAssertEqual(totals[.USD]?.net, Decimal(string: "0.23"))
        XCTAssertEqual(totals[.INR]?.net, -20)
        XCTAssertEqual(totals.count, 2)
        XCTAssertTrue(try LedgerTotals.calculate([]).isEmpty)
    }

    func testDuplicateAndMissingOperationsDoNotChangeRecords() async throws {
        let repository = LedgerRepository(url: try directory().appendingPathComponent("ledger.json"))
        let original = try record()
        _ = try await repository.create(original)
        do { _ = try await repository.create(original); XCTFail("Duplicate accepted") }
        catch { XCTAssertEqual(error as? LedgerError, .duplicate) }
        do { _ = try await repository.update(record()); XCTFail("Missing update accepted") }
        catch { XCTAssertEqual(error as? LedgerError, .missing) }
        do { _ = try await repository.delete(id: UUID()); XCTFail("Missing deletion accepted") }
        catch { XCTAssertEqual(error as? LedgerError, .missing) }
        let persisted = try await repository.read().transactions
        XCTAssertEqual(persisted, [original])
    }

    func testCorruptLedgerIsNeverOverwritten() async throws {
        let url = try directory().appendingPathComponent("ledger.json")
        let original = Data("invalid ledger".utf8)
        try original.write(to: url)
        let repository = LedgerRepository(url: url)
        do { _ = try await repository.create(record()); XCTFail("Corrupt ledger overwritten") }
        catch { XCTAssertEqual(error as? LedgerError, .invalidFile) }
        XCTAssertEqual(try Data(contentsOf: url), original)
    }

    func testFutureSchemaIsNotOverwritten() async throws {
        let url = try directory().appendingPathComponent("ledger.json")
        let original = Data(#"{"version":3,"futureRecords":[]}"#.utf8)
        try original.write(to: url)
        do { _ = try await LedgerRepository(url: url).create(record()); XCTFail("Future ledger overwritten") }
        catch { XCTAssertEqual(error as? LedgerError, .unsupportedVersion) }
        XCTAssertEqual(try Data(contentsOf: url), original)
    }

    @MainActor
    func testStorePublishesCRUDAndTotals() async throws {
        let store = LedgerStore(repository: LedgerRepository(url: try directory().appendingPathComponent("ledger.json")))
        await store.load()
        XCTAssertTrue(store.hasLoaded)
        let original = try record("0.10", kind: .income)
        try await store.save(original, editing: false)
        XCTAssertEqual(store.transactions, [original])
        XCTAssertEqual(store.totals[.INR]?.net, Decimal(string: "0.1"))
        let edited = try record("0.20", id: original.id)
        try await store.save(edited, editing: true)
        XCTAssertEqual(store.totals[.INR]?.net, Decimal(string: "-0.2"))
        try await store.delete(edited)
        XCTAssertTrue(store.transactions.isEmpty)
        XCTAssertTrue(store.totals.isEmpty)
    }

    @MainActor
    func testStoreReadErrorBlocksSavingAndSupportsRetry() async throws {
        let url = try directory().appendingPathComponent("ledger.json")
        try Data("broken".utf8).write(to: url)
        let store = LedgerStore(repository: LedgerRepository(url: url))
        await store.load()
        XCTAssertFalse(store.hasLoaded)
        XCTAssertNotNil(store.loadError)
        do { try await store.save(record(), editing: false); XCTFail("Saved before successful load") }
        catch { XCTAssertEqual(error as? LedgerError, .unavailable) }
        try FileManager.default.removeItem(at: url)
        await store.load()
        XCTAssertTrue(store.hasLoaded)
        XCTAssertNil(store.loadError)
    }

    @MainActor
    func testFailedWriteDoesNotPublishUnsavedRecords() async throws {
        let parent = try directory().appendingPathComponent("blocked")
        let store = LedgerStore(repository: LedgerRepository(url: parent.appendingPathComponent("ledger.json")))
        await store.load()
        try Data("not a directory".utf8).write(to: parent)
        do { try await store.save(record(), editing: false); XCTFail("Write unexpectedly succeeded") }
        catch { XCTAssertTrue(store.transactions.isEmpty); XCTAssertTrue(store.totals.isEmpty) }
        XCTAssertFalse(store.isSaving)
        XCTAssertEqual(try String(contentsOf: parent, encoding: .utf8), "not a directory")
    }
}
