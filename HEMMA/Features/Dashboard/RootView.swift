import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Hem", systemImage: "house.fill") }
            PlaceholderView(title: "Rum", symbol: "square.grid.2x2.fill")
                .tabItem { Label("Rum", systemImage: "square.grid.2x2.fill") }
            PlaceholderView(title: "Enheter", symbol: "lightbulb.2")
                .tabItem { Label("Enheter", systemImage: "lightbulb.2") }
            PlaceholderView(title: "Scener", symbol: "sparkles")
                .tabItem { Label("Scener", systemImage: "sparkles") }
            PlaceholderView(title: "Inställningar", symbol: "gearshape.fill")
                .tabItem { Label("Inställningar", systemImage: "gearshape.fill") }
        }
        .tint(HEMMATheme.amber)
    }
}

private struct PlaceholderView: View {
    let title: String
    let symbol: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                title,
                systemImage: symbol,
                description: Text("Den här delen byggs i nästa utvecklingsetapp.")
            )
            .background(HEMMATheme.background)
            .navigationTitle(title)
        }
    }
}