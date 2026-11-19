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
        let names = [
            "device:Hall", "device:Niklas", "device:Villemo", "device:Sovrum",
            "room:Hall", "room:Sovrum"
        ]
        var states: [String: Bool] = [:]
        for name in names {
            if let value = defaults?.object(forKey: name) as? Bool {
                states[name] = value
            }
        }
        return HEMMAWidgetEntry(date: .now, states: states)
    }

    func placeholder(in context: Context) -> HEMMAWidgetEntry {
        HEMMAWidgetEntry(date: .now, states: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (HEMMAWidgetEntry) -> Void) {
        completion(snapshot())
    }

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
    @Environment(\.widgetFamily) private var family

    private let controls: [LightingShortcut] = [
        LightingShortcut(title: "Hall", subtitle: "En lampa", symbol: "door.left.hand.open", kind: "device", name: "Hall"),
        LightingShortcut(title: "Niklas", subtitle: "Din lampa", symbol: "person.fill", kind: "device", name: "Niklas"),
        LightingShortcut(title: "Villemo", subtitle: "Lampa", symbol: "person.fill", kind: "device", name: "Villemo"),
        LightingShortcut(title: "Sovrum", subtitle: "En lampa", symbol: "bed.double.fill", kind: "device", name: "Sovrum"),
        LightingShortcut(title: "Hall", subtitle: "All belysning", symbol: "door.left.hand.open", kind: "room", name: "Hall"),
        LightingShortcut(title: "Sovrum", subtitle: "Alla lampor", symbol: "bed.double.fill", kind: "room", name: "Sovrum")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.2.fill")
                    .foregroundStyle(HEMMAWidgetStyle.amber)
                Text("HEMMA")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.3)
                    .foregroundStyle(.white)
                Spacer()
                Text("BELYSNING")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(HEMMAWidgetStyle.secondary)
            }
            .frame(height: 13)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(controls) { control in
                    let isOn = entry.states[control.statusKey]
                    Button(intent: ToggleWidgetLightIntent(kind: control.kind, name: control.name)) {
                        HStack(spacing: 6) {
                            Image(systemName: control.symbol)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(isOn == true ? HEMMAWidgetStyle.amber : HEMMAWidgetStyle.muted)
                                .frame(width: 23, height: 23)
                                .background((isOn == true ? HEMMAWidgetStyle.amber : HEMMAWidgetStyle.muted).opacity(0.13),
                                            in: RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(control.title)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text(control.subtitle)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(HEMMAWidgetStyle.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                            Circle()
                                .fill(isOn == true ? HEMMAWidgetStyle.amber : HEMMAWidgetStyle.muted.opacity(0.65))
                                .frame(width: 6, height: 6)
                                .shadow(color: isOn == true ? HEMMAWidgetStyle.amber.opacity(0.8) : .clear, radius: 4)
                        }
                        .padding(.horizontal, 7)
                        .frame(maxWidth: .infinity, minHeight: 42, maxHeight: 42)
                        .background(.white.opacity(isOn == true ? 0.085 : 0.045),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder((isOn == true ? HEMMAWidgetStyle.amber : .white).opacity(isOn == true ? 0.28 : 0.07),
                                              lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
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
