import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: HomeKitStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Inställningar")
                        .font(.largeTitle.bold())
                        .foregroundStyle(HEMMATheme.warmWhite)

                    VStack(alignment: .leading, spacing: 14) {
                        Label("Anslutning till Apple Hem", systemImage: "house")
                            .font(.headline)
                            .foregroundStyle(HEMMATheme.warmWhite)
                        HStack {
                            Circle()
                                .fill(store.isAuthorized ? Color.green : Color.orange)
                                .frame(width: 9, height: 9)
                            Text(store.isLoading ? "Ansluter…" : (store.isAuthorized ? "Ansluten" : "Åtkomst saknas eller inväntas"))
                                .font(.subheadline)
                                .foregroundStyle(HEMMATheme.secondaryText)
                            Spacer()
                            Button {
                                store.refresh()
                            } label: {
                                Label("Uppdatera", systemImage: "arrow.clockwise")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(HEMMATheme.amber)
                            }
                            .disabled(store.isLoading)
                        }
                        Divider().overlay(HEMMATheme.secondaryText.opacity(0.25))
                        settingRow("Hem", value: "\(store.homes.count)")
                        settingRow("Rum", value: "\(store.roomCount)")
                        settingRow("Lampor", value: "\(store.lightAccessories.count)")
                        settingRow("Övriga tillbehör", value: "\(store.homes.flatMap(\.accessories).filter { !store.isLight($0) }.count)")
                    }
                    .padding(18)
                    .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))

                    VStack(alignment: .leading, spacing: 10) {
                        Label("Så fungerar HEMMA", systemImage: "info.circle")
                            .font(.headline)
                            .foregroundStyle(HEMMATheme.warmWhite)
                        Text("HEMMA använder Apple Hem som enda källa för enheter och status. Dina Matter-tillbehör fortsätter att vara parkopplade via Apples Hem-app. HEMMA skapar ingen separat kopia av ditt smarta hem.")
                            .font(.subheadline)
                            .foregroundStyle(HEMMATheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))

                    if let error = store.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 4)
                    }

                    Text("HEMMA · Första versionen")
                        .font(.caption)
                        .foregroundStyle(HEMMATheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(20)
            }
            .background(HEMMATheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func settingRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(HEMMATheme.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(HEMMATheme.warmWhite)
        }
    }
}
