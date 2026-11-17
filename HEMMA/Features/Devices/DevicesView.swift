import SwiftUI
import HomeKit

struct DevicesView: View {
    @EnvironmentObject private var store: HomeKitStore

    private var accessories: [HMAccessory] {
        store.homes.flatMap(\.accessories).sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var availableLights: Int {
        accessories.filter { store.isLight($0) && $0.isReachable }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if store.isLoading {
                        info("Ansluter till Apple Hem", detail: "Hämtar dina tillbehör.")
                    } else if !store.isAuthorized {
                        info("Åtkomst till Apple Hem saknas", detail: "Tillåt HEMMA att komma åt ditt hem i iPhone-inställningarna och försök igen.")
                    } else if accessories.isEmpty {
                        info("Inga enheter hittades", detail: "När Apple Hem har tillbehör visas de här.")
                    } else {
                        HStack(spacing: 10) {
                            metric(value: "\(accessories.count)", label: "Enheter", symbol: "square.3.layers.3d")
                            metric(value: "\(availableLights)", label: "Tillgängliga lampor", symbol: "lightbulb.fill")
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Alla enheter")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(HEMMATheme.warmWhite)
                                Spacer()
                                Text("\(accessories.count)")
                                    .font(.caption.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(HEMMATheme.secondaryText)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(HEMMATheme.elevatedSurface, in: Capsule())
                            }

                            ForEach(accessories, id: \.uniqueIdentifier) { accessory in
                                deviceCard(accessory)
                            }
                        }
                    }

                    if let error = store.errorMessage {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 30)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(HEMMATheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .background(HEMMATheme.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(store.isAuthorized ? Color.green : HEMMATheme.secondaryText)
                    .frame(width: 7, height: 7)
                Text(store.isAuthorized ? "APPLE HEM ANSLUTET" : "SMARTA HEMMET")
                    .font(.caption.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(HEMMATheme.secondaryText)
            }
            Text("Enheter")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .tracking(-0.8)
                .foregroundStyle(HEMMATheme.warmWhite)
            Text("All din belysning och smarta tillbehör, samlade på ett ställe.")
                .font(.subheadline)
                .foregroundStyle(HEMMATheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func metric(value: String, label: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(HEMMATheme.amber)
                .frame(width: 42, height: 42)
                .background(HEMMATheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(HEMMATheme.warmWhite)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(HEMMATheme.secondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private func deviceCard(_ accessory: HMAccessory) -> some View {
        let isLight = store.isLight(accessory)
        let state = store.powerState(for: accessory)
        let isPending = store.isPowerCommandPending(for: accessory)

        return Button {
            guard isLight, accessory.isReachable, state != nil, !isPending else { return }
            store.setPower(state != true, for: accessory)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 17)
                        .fill(isLight && state == true ? HEMMATheme.amber.opacity(0.16) : HEMMATheme.elevatedSurface)
                        .frame(width: 54, height: 54)
                    Image(systemName: isLight ? (state == true ? "lightbulb.fill" : "lightbulb") : "powerplug.fill")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(isLight && state == true ? HEMMATheme.amber : HEMMATheme.secondaryText)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(accessory.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(HEMMATheme.warmWhite)
                        .lineLimit(1)
                    Text(accessory.room?.name ?? "Inte tilldelad något rum")
                        .font(.subheadline)
                        .foregroundStyle(HEMMATheme.secondaryText)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(accessory.isReachable ? (state == true && isLight ? HEMMATheme.amber : Color.green) : Color.red)
                            .frame(width: 6, height: 6)
                        Text(!accessory.isReachable ? "Kan inte nås" : (isLight ? (state == true ? "Tänd" : state == false ? "Släckt" : "Status okänd") : "Tillgänglig"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(HEMMATheme.secondaryText)
                    }
                }

                Spacer(minLength: 4)

                if isPending {
                    ProgressView()
                        .tint(HEMMATheme.amber)
                        .frame(width: 46, height: 46)
                } else if isLight {
                    Image(systemName: state == true ? "power.circle.fill" : "power.circle")
                        .font(.system(size: 34, weight: .regular))
                        .foregroundStyle(accessory.isReachable ? (state == true ? HEMMATheme.amber : HEMMATheme.secondaryText) : HEMMATheme.secondaryText.opacity(0.45))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(HEMMATheme.secondaryText.opacity(0.65))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [HEMMATheme.surface, HEMMATheme.surface.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(isLight && state == true ? HEMMATheme.amber.opacity(0.22) : Color.white.opacity(0.035), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .disabled(!isLight || !accessory.isReachable || state == nil || isPending)
        .accessibilityLabel("\(accessory.name), \(state == true ? "tänd" : "släckt"). Tryck för att växla.")
        .accessibilityHint("Tryck på hela enhetskortet för att tända eller släcka lampan.")
    }

    private func info(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.headline).foregroundStyle(HEMMATheme.warmWhite)
            Text(detail).font(.subheadline).foregroundStyle(HEMMATheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }
}
