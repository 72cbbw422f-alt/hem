import SwiftUI
import HomeKit

struct ScenesView: View {
    @EnvironmentObject private var store: HomeKitStore
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("STÄMNING MED ETT TRYCK")
                            .font(.caption.weight(.bold))
                            .tracking(1.5)
                            .foregroundStyle(HEMMATheme.amber)
                        Text("Scener")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(HEMMATheme.warmWhite)
                        Text("Låt ljuset sätta känslan i hemmet.")
                            .font(.subheadline)
                            .foregroundStyle(HEMMATheme.secondaryText)
                    }

                    if store.isLoading {
                        message("Ansluter till Apple Hem", detail: "Hämtar dina sparade scener.")
                    } else if !store.isAuthorized {
                        message("Åtkomst till Apple Hem saknas", detail: "Tillåt HEMMA att komma åt ditt hem i iPhone-inställningarna och försök igen.")
                    } else if store.scenes.isEmpty {
                        message("Inga scener hittades", detail: "Skapa scener i Apples Hem-app så visas de här.")
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(store.scenes, id: \.actionSet.uniqueIdentifier) { item in
                                Button {
                                    store.activate(item.actionSet, in: item.home)
                                } label: {
                                    VStack(alignment: .leading, spacing: 15) {
                                        HStack {
                                            Image(systemName: sceneSymbol(item.actionSet.name))
                                                .font(.system(size: 23, weight: .medium))
                                                .foregroundStyle(HEMMATheme.amber)
                                                .frame(width: 48, height: 48)
                                                .background(HEMMATheme.amber.opacity(0.14), in: RoundedRectangle(cornerRadius: 16))
                                            Spacer()
                                            if store.isScenePending(item.actionSet) {
                                                ProgressView().tint(HEMMATheme.amber)
                                            } else {
                                                Image(systemName: "arrow.up.right")
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(HEMMATheme.secondaryText)
                                            }
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.actionSet.name)
                                                .font(.headline.weight(.semibold))
                                                .foregroundStyle(HEMMATheme.warmWhite)
                                                .lineLimit(1)
                                            Text(item.home.name)
                                                .font(.caption)
                                                .foregroundStyle(HEMMATheme.secondaryText)
                                        }
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
                                    .background(
                                        LinearGradient(colors: [HEMMATheme.elevatedSurface, HEMMATheme.surface], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .strokeBorder(HEMMATheme.amber.opacity(0.10), lineWidth: 1)
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(store.isScenePending(item.actionSet))
                            }
                        }
                    }

                    if let error = store.errorMessage {
                        Text(error).font(.footnote).foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 34)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .background(HEMMATheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .background(HEMMATheme.background.ignoresSafeArea())
    }

    private func sceneSymbol(_ name: String) -> String {
        let key = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if key.contains("morgon") { return "sun.max.fill" }
        if key.contains("film") || key.contains("bio") { return "tv.fill" }
        if key.contains("kvall") || key.contains("natt") { return "moon.stars.fill" }
        if key.contains("borta") || key.contains("away") { return "house.slash.fill" }
        if key.contains("middag") || key.contains("mat") { return "fork.knife" }
        return "sparkles"
    }

    private func message(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.headline).foregroundStyle(HEMMATheme.warmWhite)
            Text(detail).font(.subheadline).foregroundStyle(HEMMATheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }
}
