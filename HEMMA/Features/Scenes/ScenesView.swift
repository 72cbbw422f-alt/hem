import SwiftUI
import HomeKit

struct ScenesView: View {
    @EnvironmentObject private var store: HomeKitStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Scener")
                        .font(.largeTitle.bold())
                        .foregroundStyle(HEMMATheme.warmWhite)
                    Text("Dina scener från Apple Hem")
                        .font(.subheadline)
                        .foregroundStyle(HEMMATheme.secondaryText)

                    if store.isLoading {
                        message("Ansluter till Apple Hem", detail: "Hämtar dina sparade scener.")
                    } else if store.scenes.isEmpty {
                        message("Inga scener hittades", detail: "Skapa scener i Apples Hem-app så visas de här.")
                    } else {
                        ForEach(store.scenes, id: \.actionSet.uniqueIdentifier) { item in
                            Button {
                                store.activate(item.actionSet, in: item.home)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "sparkles")
                                        .font(.title2)
                                        .foregroundStyle(HEMMATheme.amber)
                                        .frame(width: 48, height: 48)
                                        .background(HEMMATheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 15))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.actionSet.name)
                                            .font(.headline)
                                            .foregroundStyle(HEMMATheme.warmWhite)
                                        Text(item.home.name)
                                            .font(.caption)
                                            .foregroundStyle(HEMMATheme.secondaryText)
                                    }
                                    Spacer()
                                    if store.isScenePending(item.actionSet) {
                                        ProgressView()
                                            .tint(HEMMATheme.amber)
                                    } else {
                                        Image(systemName: "play.fill")
                                            .font(.caption)
                                            .foregroundStyle(HEMMATheme.amber)
                                    }
                                }
                                .padding(16)
                                .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))
                            }
                            .buttonStyle(.plain)
                            .disabled(store.isScenePending(item.actionSet))
                        }
                    }

                    if let error = store.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(20)
            }
            .background(HEMMATheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func message(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.headline).foregroundStyle(HEMMATheme.warmWhite)
            Text(detail).font(.subheadline).foregroundStyle(HEMMATheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))
    }
}
