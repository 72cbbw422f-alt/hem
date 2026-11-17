import SwiftUI
import HomeKit

struct DevicesView: View {
    @EnvironmentObject private var store: HomeKitStore

    private var accessories: [HMAccessory] {
        store.homes.flatMap(\.accessories).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Enheter")
                        .font(.largeTitle.bold())
                        .foregroundStyle(HEMMATheme.warmWhite)
                    Text("Tillbehör som finns i Apple Hem")
                        .font(.subheadline)
                        .foregroundStyle(HEMMATheme.secondaryText)

                    if store.isLoading {
                        info("Ansluter till Apple Hem", detail: "Hämtar dina tillbehör.")
                    } else if !store.isAuthorized {
                        info("Åtkomst till Apple Hem saknas", detail: "Tillåt HEMMA att komma åt ditt hem i iPhone-inställningarna och försök igen.")
                    } else if accessories.isEmpty {
                        info("Inga enheter hittades", detail: "När Apple Hem har tillbehör visas de här.")
                    } else {
                        ForEach(accessories, id: \.uniqueIdentifier) { accessory in
                            deviceRow(accessory)
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

    private func deviceRow(_ accessory: HMAccessory) -> some View {
        HStack(spacing: 13) {
            Image(systemName: store.isLight(accessory) ? "lightbulb.fill" : "powerplug.fill")
                .font(.title3)
                .foregroundStyle(HEMMATheme.amber)
                .frame(width: 44, height: 44)
                .background(HEMMATheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(accessory.name)
                    .font(.headline)
                    .foregroundStyle(HEMMATheme.warmWhite)
                Text(accessory.isReachable ? "Tillgänglig" : "Kan inte nås")
                    .font(.caption)
                    .foregroundStyle(accessory.isReachable ? HEMMATheme.secondaryText : .red)
            }
            Spacer()
            if store.isLight(accessory), !accessory.isReachable {
                Text("Ej nåbar")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if store.isLight(accessory), store.powerState(for: accessory) != nil {
                Toggle("Enhet", isOn: Binding(
                    get: { store.powerState(for: accessory) ?? false },
                    set: { store.setPower($0, for: accessory) }
                ))
                .labelsHidden()
                .tint(HEMMATheme.amber)
                .disabled(store.isPowerCommandPending(for: accessory))
            } else if store.isLight(accessory) {
                Text("Okänd status")
                    .font(.caption)
                    .foregroundStyle(HEMMATheme.secondaryText)
            }
        }
        .padding(15)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))
    }

    private func info(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.headline).foregroundStyle(HEMMATheme.warmWhite)
            Text(detail).font(.subheadline).foregroundStyle(HEMMATheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))
    }
}
