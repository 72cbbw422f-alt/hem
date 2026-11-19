import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var homeStore = HomeKitStore()
    @State private var pendingWidgetAction: WidgetLightingAction?

    var body: some View {
        ZStack {
            HEMMATheme.background.ignoresSafeArea()
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
            .toolbarBackground(HEMMATheme.surface, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .background(HEMMATheme.background)
        }
        .environmentObject(homeStore)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                homeStore.refresh()
                homeStore.requestFreshLightingStates()
            }
        }
        .onOpenURL { url in
            guard url.scheme?.lowercased() == "hemma",
                  url.host?.lowercased() == "lights" else { return }
            let components = url.pathComponents
                .filter { $0 != "/" }
                .map { $0.removingPercentEncoding ?? $0 }
            guard components.count == 2,
                  ["device", "room", "all"].contains(components[0]) else {
                homeStore.reportWidgetError("Widgetkommandot hade ett ogiltigt format: \(url.absoluteString)")
                return
            }
            pendingWidgetAction = WidgetLightingAction(kind: components[0], name: components[1])
            performPendingWidgetActionIfPossible()
        }
        .onChange(of: homeStore.revision) { _, _ in
            performPendingWidgetActionIfPossible()
        }
        .onChange(of: homeStore.isLoading) { _, _ in
            performPendingWidgetActionIfPossible()
        }
        .onChange(of: homeStore.isAuthorized) { _, _ in
            performPendingWidgetActionIfPossible()
        }
        .alert("HEMMA – belysning", isPresented: Binding(
            get: { homeStore.errorMessage != nil },
            set: { if !$0 { homeStore.clearErrorMessage() } }
        )) {
            Button("OK") { homeStore.clearErrorMessage() }
        } message: {
            Text(homeStore.errorMessage ?? "Kommandot kunde inte genomföras.")
        }
    }

    private func performPendingWidgetActionIfPossible() {
        guard let action = pendingWidgetAction, !homeStore.isLoading else { return }
        guard homeStore.isAuthorized else {
            // Keep the action unexecuted; the dashboard explains how to grant Home access.
            return
        }
        pendingWidgetAction = nil
        switch action.kind {
        case "device": homeStore.toggleLight(named: action.name)
        case "room": homeStore.toggleRoom(named: action.name)
        case "all": homeStore.setAllLights(homeStore.allLightsAreOn != true)
        default: break
        }
    }
}

private struct WidgetLightingAction {
    let kind: String
    let name: String
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
