import SwiftUI
import HomeKit

struct DashboardView: View {
    @StateObject private var homeStore = HomeKitStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    HStack(spacing: 12) {
                        summaryCard(title: "Lampor", value: homeStore.isAuthorized ? "\(homeStore.lightAccessories.count)" : "—", symbol: "lightbulb.fill")
                        summaryCard(title: "Rum", value: homeStore.isAuthorized ? "\(homeStore.roomCount)" : "—", symbol: "square.grid.2x2.fill")
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ditt hem")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(HEMMATheme.warmWhite)
                        if homeStore.isLoading {
                            statusCard(title: "Ansluter till Apple Hem", detail: "Hämtar dina hem och tillbehör.", symbol: "house")
                        } else if !homeStore.isAuthorized {
                            statusCard(title: "Åtkomst inväntas", detail: homeStore.errorMessage ?? "Tillåt HEMMA att läsa ditt hem när iOS frågar.", symbol: "lock")
                        } else if homeStore.homes.isEmpty {
                            statusCard(title: "Inget hem hittades", detail: "Skapa eller konfigurera ett hem i Apples Hem-app först.", symbol: "house")
                        } else {
                            ForEach(homeStore.homes, id: \.uniqueIdentifier) { home in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(home.name)
                                        .font(.headline)
                                        .foregroundStyle(HEMMATheme.warmWhite)
                                    Text("\(home.rooms.count) rum · \(home.accessories.count) tillbehör")
                                        .font(.subheadline)
                                        .foregroundStyle(HEMMATheme.secondaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(HEMMATheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundStyle(HEMMATheme.secondaryText)
            Text("HEMMA")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(HEMMATheme.warmWhite)
            Text("Allt hemma. Under kontroll.")
                .font(.subheadline)
                .foregroundStyle(HEMMATheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summaryCard(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(HEMMATheme.amber)
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(HEMMATheme.warmWhite)
            Text(title)
                .font(.caption)
                .foregroundStyle(HEMMATheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))
    }

    private func statusCard(title: String, detail: String, symbol: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline).foregroundStyle(HEMMATheme.warmWhite)
                Text(detail).font(.subheadline).foregroundStyle(HEMMATheme.secondaryText)
            }
        } icon: {
            Image(systemName: symbol).font(.title2).foregroundStyle(HEMMATheme.amber)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))
    }
}
