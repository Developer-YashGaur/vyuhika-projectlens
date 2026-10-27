import SwiftUI

struct HomeView: View {
    var body: some View {
        OrbitEmptyState(
            symbol: "circle.hexagongrid",
            eyebrow: "PROJECTLENS · YOUR PERSONAL ORBIT",
            title: "Big ideas.\nClearer horizons.",
            message: "A little perspective for everything you’re building.",
            detail: "Your workspace is ready to explore. Financial tools are still being built; no financial data is stored.",
            identifier: "home.empty"
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationShell()
    }
}
