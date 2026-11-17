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
    func placeholder(in context: Context) -> HEMMAWidgetEntry {
        HEMMAWidgetEntry(date: .now)
    }

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
                .containerBackground(for: .widget) {\n                    LinearGradient(colors: [HEMMAWidgetStyle.surface, HEMMAWidgetStyle.background], startPoint: .topLeading, endPoint: .bottomTrailing)\n                }
        }
        .configurationDisplayName("HEMMA – Belysning")
        .description("Öppna HEMMA och styr belysningen i ditt hem.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct HEMMALightingWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.2.fill")
                    .foregroundStyle(HEMMAWidgetStyle.amber)
                Text("HEMMA")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "house.fill")
                    .foregroundStyle(HEMMAWidgetStyle.secondary)
            }

            Spacer(minLength: 0)

            Link(destination: URL(string: "hemma://lights/toggle")!) {
                HStack(spacing: 12) {
                    Image(systemName: "power")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(HEMMAWidgetStyle.background)
                        .frame(width: 44, height: 44)
                        .background(LinearGradient(colors: [HEMMAWidgetStyle.amber, Color(red: 0.82, green: 0.43, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Ditt hem, ett tryck bort")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Öppna ljuskontrollen")
                            .font(.caption)
                            .foregroundStyle(HEMMAWidgetStyle.secondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(HEMMAWidgetStyle.secondary)
                }
            }
            .buttonStyle(.plain)

            if family == .systemMedium {
                Text("Snabb åtkomst till hemmets belysning")
                    .font(.caption2)
                    .foregroundStyle(HEMMAWidgetStyle.secondary)
                    .lineLimit(1)
            }
        }
        .padding(16)
    }
}

@main
struct HEMMAWidgetBundle: WidgetBundle {
    var body: some Widget {
        HEMMALightingWidget()
    }
}
