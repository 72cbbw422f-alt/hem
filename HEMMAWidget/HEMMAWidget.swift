import SwiftUI
import WidgetKit

private enum HEMMAWidgetStyle {
    static let background = Color(red: 0.035, green: 0.032, blue: 0.030)
    static let surface = Color(red: 0.145, green: 0.124, blue: 0.105)
    static let amber = Color(red: 1.0, green: 0.69, blue: 0.31)
    static let secondary = Color(red: 0.665, green: 0.635, blue: 0.590)
}

struct HEMMAWidgetEntry: TimelineEntry {
    let date: Date
}

struct HEMMAWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HEMMAWidgetEntry { HEMMAWidgetEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (HEMMAWidgetEntry) -> Void) {
        completion(HEMMAWidgetEntry(date: .now))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HEMMAWidgetEntry>) -> Void) {
        completion(Timeline(entries: [HEMMAWidgetEntry(date: .now)], policy: .never))
    }
}

struct HEMMALightingWidget: Widget {
    let kind = "HEMMALightingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HEMMAWidgetProvider()) { _ in
            HEMMALightingWidgetView()
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
    @Environment(\\.widgetFamily) private var family

    private let controls: [LightingShortcut] = [
        LightingShortcut(title: "Hall", subtitle: "En lampa", symbol: "door.left.hand.open", kind: "device", name: "Hall"),
        LightingShortcut(title: "Niklas", subtitle: "Din lampa", symbol: "person.fill", kind: "device", name: "Niklas"),
        LightingShortcut(title: "Villemo", subtitle: "Lampa", symbol: "person.fill", kind: "device", name: "Villemo"),
        LightingShortcut(title: "Sovrum", subtitle: "En lampa", symbol: "bed.double.fill", kind: "device", name: "Sovrum"),
        LightingShortcut(title: "Hall", subtitle: "All belysning", symbol: "door.left.hand.open", kind: "room", name: "Hall"),
        LightingShortcut(title: "Sovrum", subtitle: "Alla lampor", symbol: "bed.double.fill", kind: "room", name: "Sovrum")
    ]

    private var visibleControls: [LightingShortcut] {
        family == .systemLarge ? controls : Array(controls.prefix(6))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.2.fill")
                    .foregroundStyle(HEMMAWidgetStyle.amber)
                Text("HEMMA")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(.white)
                Spacer()
                Text("BELYSNING")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(HEMMAWidgetStyle.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                ForEach(visibleControls) { control in
                    Link(destination: control.url) {
                        VStack(alignment: .leading, spacing: 7) {
                            Image(systemName: control.symbol)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(HEMMAWidgetStyle.amber)
                                .frame(width: 32, height: 32)
                                .background(HEMMAWidgetStyle.amber.opacity(0.13), in: RoundedRectangle(cornerRadius: 11))
                            Text(control.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(control.subtitle)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(HEMMAWidgetStyle.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
                        .padding(9)
                        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 15))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15)
                                .strokeBorder(HEMMAWidgetStyle.amber.opacity(0.10), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
    }
}

private struct LightingShortcut: Identifiable {
    let title: String
    let subtitle: String
    let symbol: String
    let kind: String
    let name: String

    var id: String { "\\(kind)-\\(name)" }
    var url: URL { URL(string: "hemma://lights/\\(kind)/\\(name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name)")! }
}

@main
struct HEMMAWidgetBundle: WidgetBundle {
    var body: some Widget { HEMMALightingWidget() }
}
