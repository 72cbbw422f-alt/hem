import SwiftUI

struct RootView: View {
    @StateObject private var homeStore = HomeKitStore()
    @State private var pendingWidgetLightingAction = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            HEMMATheme.background.ignoresSafeArea()
            TabView(selection: $selectedTab) {
                DashboardView(selectedTab: $selectedTab)
                    .tag(0)
                    .tabItem { Label("Hem", systemImage: "house.fill") }
                RoomsView()
                    .tabItem { Label("Rum", systemImage: "square.grid.2x2.fill") }
                    .tag(1)
                DevicesView()
                    .tabItem { Label("Enheter", systemImage: "lightbulb.2") }
                    .tag(2)
                ScenesView()
                    .tabItem { Label("Scener", systemImage: "sparkles") }
                    .tag(3)
                SettingsView()
                    .tabItem { Label("Inställningar", systemImage: "gearshape.fill") }
                    .tag(4)
            }
            .tint(HEMMATheme.amber)
            .toolbarBackground(HEMMATheme.surface, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .background(HEMMATheme.background)
        }
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
