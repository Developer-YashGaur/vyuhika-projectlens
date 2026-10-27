import SwiftUI

@main
struct ProjectLensApp: App {
    @StateObject private var ledger: LedgerStore

    init() {
        var url = LedgerRepository.defaultURL
        #if DEBUG
        // UI tests create their own ledger, never erase or seed a user's records.
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--ui-test-ledger"), arguments.indices.contains(index + 1),
           let identifier = UUID(uuidString: arguments[index + 1]) {
            url = URL.cachesDirectory.appending(path: "KoshvyaUITests/\(identifier.uuidString).json")
        }
        #endif
        _ledger = StateObject(wrappedValue: LedgerStore(repository: LedgerRepository(url: url)))
    }

    var body: some Scene {
        WindowGroup {
            NavigationShell()
                .environmentObject(ledger)
                .task { await ledger.load() }
        }
    }
}
