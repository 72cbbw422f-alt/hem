import SwiftUI
import HomeKit

struct ScenesView: View {
    @EnvironmentObject private var store: HomeKitStore
    @State private var showingAutomations = false
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(showingAutomations ? "SMARTA REGLER I DITT HEM" : "STÄMNING MED ETT TRYCK")
                            .font(.caption.weight(.bold))
                            .tracking(1.5)
                            .foregroundStyle(HEMMATheme.amber)
                        Text(showingAutomations ? "Automatiseringar" : "Scener")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(HEMMATheme.warmWhite)
                        Text(showingAutomations ? "Se och styr reglerna som får hemmet att sköta sig självt." : "Låt ljuset sätta känslan i hemmet.")
                            .font(.subheadline)
                            .foregroundStyle(HEMMATheme.secondaryText)
                    }

                    Picker("Visa", selection: $showingAutomations) {
                        Text("Scener").tag(false)
                        Text("Automatiseringar").tag(true)
                    }
                    .pickerStyle(.segmented)

                    if store.isLoading {
                        message("Ansluter till Apple Hem", detail: "Hämtar dina scener och automatiseringar.")
                    } else if !store.isAuthorized {
                        message("Åtkomst till Apple Hem saknas", detail: "Tillåt HEMMA att komma åt ditt hem i iPhone-inställningarna och försök igen.")
                    } else if showingAutomations {
                        automationsContent
                    } else {
                        scenesContent
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

    @ViewBuilder
    private var scenesContent: some View {
        if store.scenes.isEmpty {
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
                        .background(LinearGradient(colors: [HEMMATheme.elevatedSurface, HEMMATheme.surface], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
    }

    @ViewBuilder
    private var automationsContent: some View {
        if store.automations.isEmpty {
            message("Inga automatiseringar hittades", detail: "Automatiseringar som skapats i Apples Hem-app visas här när de finns tillgängliga.")
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Dina automatiseringar")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(HEMMATheme.warmWhite)
                    Spacer()
                    Text("\(store.automations.count)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(HEMMATheme.secondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(HEMMATheme.elevatedSurface, in: Capsule())
                }
                ForEach(store.automations, id: \.trigger.uniqueIdentifier) { item in
                    automationCard(item.trigger, homeName: item.home.name)
                }
                Text("Automatiseringarna hanteras av Apple Hem. HEMMA ändrar bara om de är aktiva eller inaktiva.")
                    .font(.caption)
                    .foregroundStyle(HEMMATheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
    }

    private func automationCard(_ trigger: HMTrigger, homeName: String) -> some View {
        let pending = store.isTriggerPending(trigger)
        return VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 12) {
                Image(systemName: automationSymbol(for: trigger))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(HEMMATheme.amber)
                    .frame(width: 46, height: 46)
                    .background(HEMMATheme.amber.opacity(0.13), in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 4) {
                    Text(trigger.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(HEMMATheme.warmWhite)
                        .lineLimit(2)
                    Text(homeName)
                        .font(.caption)
                        .foregroundStyle(HEMMATheme.secondaryText)
                }
                Spacer(minLength: 4)
                if pending {
                    ProgressView().tint(HEMMATheme.amber)
                } else {
                    Button {
                        store.setTriggerEnabled(!trigger.isEnabled, trigger: trigger)
                    } label: {
                        Text(trigger.isEnabled ? "Aktiv" : "Av")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(trigger.isEnabled ? Color.green : HEMMATheme.secondaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background((trigger.isEnabled ? Color.green : HEMMATheme.secondaryText).opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(trigger.isEnabled ? "Inaktivera" : "Aktivera") \(trigger.name)")
                }
            }
            HStack(spacing: 7) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                Text(automationDescription(for: trigger))
                    .font(.caption)
                Spacer()
                Text("\(trigger.actionSets.count) scener")
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(HEMMATheme.secondaryText)
        }
        .padding(16)
        .background(LinearGradient(colors: [HEMMATheme.elevatedSurface, HEMMATheme.surface], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(trigger.isEnabled ? Color.green.opacity(0.14) : Color.white.opacity(0.04), lineWidth: 1)
        }
    }

    private func automationDescription(for trigger: HMTrigger) -> String {
        if let timer = trigger as? HMTimerTrigger {
            let time = timer.fireDate.formatted(date: .omitted, time: .shortened)
            return "Tidsstyrd · Nästa angivna tid \(time)"
        }
        if trigger is HMEventTrigger {
            return "Utlöses av en händelse eller ett villkor"
        }
        return "Automatisering i Apple Hem"
    }

    private func automationSymbol(for trigger: HMTrigger) -> String {
        if trigger is HMTimerTrigger { return "clock.fill" }
        if trigger is HMEventTrigger { return "sensor.fill" }
        return "gearshape.2.fill"
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
