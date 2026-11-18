import SwiftUI
import WidgetKit

private enum HEMMAWidgetStyle {
    static let background = Color(red: 0.035, green: 0.032, blue: 0.030)
    static let surface = Color(red: 0.145, green: 0.124, blue: 0.105)
    static let amber = Color(red: 1.0, green: 0.69, blue: 0.31)
    static let muted = Color(red: 0.48, green: 0.46, blue: 0.43)
    static let secondary = Color(red: 0.665, green: 0.635, blue: 0.590)
}

struct HEMMAWidgetEntry: TimelineEntry {
    let date: Date
    let states: [String: Bool]
}

struct HEMMAWidgetProvider: TimelineProvider {
    private func snapshot() -> HEMMAWidgetEntry {
        let defaults = UserDefaults(suiteName: LightingStatusStore.suiteName)
        let keys = ["device:Hall", "device:Niklas", "device:Villemo", "device:Sovrum", "room:Hall", "room:Sovrum"]
        var states: [String: Bool] = [:]
        for key in keys {
            if let value = defaults?.object(forKey: key) as? Bool { states[key] = value }
        }
        return HEMMAWidgetEntry(date: .now, states: states)
    }

    func placeholder(in context: Context) -> HEMMAWidgetEntry { HEMMAWidgetEntry(date: .now, states: [:]) }
    func getSnapshot(in context: Context, completion: @escaping (HEMMAWidgetEntry) -> Void) { completion(snapshot()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HEMMAWidgetEntry>) -> Void) {
        completion(Timeline(entries: [snapshot()], policy: .never))
    }
}

struct HEMMALightingWidget: Widget {
    let kind = "HEMMALightingWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HEMMAWidgetProvider()) { entry in
            HEMMALightingWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [HEMMAWidgetStyle.surface, HEMMAWidgetStyle.background],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
        }
        .configurationDisplayName("HEMMA – Belysning")
        .description("Sex genvägar till dina lampor och rum.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct HEMMALightingWidgetView: View {
    let entry: HEMMAWidgetEntry

    private let controls: [LightingShortcut] = [
        .init(title: "Hall", subtitle: "Lampa", symbol: "door.left.hand.open", kind: "device", name: "Hall"),
        .init(title: "Niklas", subtitle: "Lampa", symbol: "person.fill", kind: "device", name: "Niklas"),
        .init(title: "Villemo", subtitle: "Lampa", symbol: "person.fill", kind: "device", name: "Villemo"),
        .init(title: "Sovrum", subtitle: "Lampa", symbol: "bed.double.fill", kind: "device", name: "Sovrum"),
        .init(title: "Hall", subtitle: "Hela rummet", symbol: "door.left.hand.open", kind: "room", name: "Hall"),
        .init(title: "Sovrum", subtitle: "Hela rummet", symbol: "bed.double.fill", kind: "room", name: "Sovrum")
    ]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "lightbulb.2.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HEMMAWidgetStyle.amber)
                Text("HEMMA")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(.white)
                Spacer()
                Text("BELYSNING")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(HEMMAWidgetStyle.secondary)
            }
            .padding(.horizontal, 3)
            .frame(height: 18)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 7) {
                ForEach(controls) { control in
                    let state = entry.states[control.statusKey]
                    Button(intent: ToggleWidgetLightIntent(kind: control.kind, name: control.name)) {
                        VStack(spacing: 4) {
                            HStack {
                                Spacer(minLength: 0)
                                Image(systemName: control.symbol)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(state == true ? HEMMAWidgetStyle.amber : HEMMAWidgetStyle.muted)
                                Spacer(minLength: 0)
                                Circle()
                                    .fill(indicatorColor(for: state))
                                    .frame(width: 7, height: 7)
                                    .shadow(color: state == true ? HEMMAWidgetStyle.amber.opacity(0.8) : .clear, radius: 4)
                            }
                            Text(control.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            Text(control.subtitle)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(HEMMAWidgetStyle.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: 49, maxHeight: 49)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(state == true ? HEMMAWidgetStyle.amber.opacity(0.10) : .white.opacity(0.045),
                                    in: RoundedRectangle(cornerRadius: 13))
                        .overlay {
                            RoundedRectangle(cornerRadius: 13)
                                .strokeBorder(state == true ? HEMMAWidgetStyle.amber.opacity(0.35) : .white.opacity(0.08), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func indicatorColor(for state: Bool?) -> Color {
        guard let state else { return HEMMAWidgetStyle.muted.opacity(0.45) }
        return state ? HEMMAWidgetStyle.amber : Color(red: 0.34, green: 0.34, blue: 0.33)
    }
}

private struct LightingShortcut: Identifiable {
    let title: String
    let subtitle: String
    let symbol: String
    let kind: String
    let name: String
    var id: String { "\(kind)-\(name)" }
    var statusKey: String { "\(kind):\(name)" }
}

@main
struct HEMMAWidgetBundle: WidgetBundle {
    var body: some Widget { HEMMALightingWidget() }
}
