import SwiftUI

struct RootView: View {
    @StateObject private var homeStore = HomeKitStore()
    @State private var pendingWidgetLightingAction = false

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Hem", systemImage: "house.fill") }
            RoomsView()
                .tabItem { Label("Rum", systemImage: "square.grid.2x2.fill") }
            DevicesView()
                .tabItem { Label("Enheter", systemImage: "lightbulb.2") }
            ScenesView()
                .tabItem { Label("Scener", systemImage: "sparkles") }
            SettingsView()
                .tabItem { Label("Inställningar", systemImage: "gearshape.fill") }
        }
        .tint(HEMMATheme.amber)
        .environmentObject(homeStore)
        .onOpenURL { url in
            guard url.scheme == "hemma", url.host == "lights", url.path == "/toggle" else { return }
            pendingWidgetLightingAction = true
            performPendingWidgetActionIfPossible()
        }
        .onChange(of: homeStore.revision) { _, _ in
            performPendingWidgetActionIfPossible()
        }
    }

    private func performPendingWidgetActionIfPossible() {
        guard pendingWidgetLightingAction, !homeStore.isLoading else { return }
        guard homeStore.isAuthorized else {
            // Keep the action unexecuted; the dashboard explains how to grant Home access.
            return
        }
        pendingWidgetLightingAction = false
        homeStore.setAllLights(homeStore.allLightsAreOn != true)
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
