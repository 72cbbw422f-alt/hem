import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    HStack(spacing: 12) {
                        summaryCard(title: "Lampor tända", value: "—", symbol: "lightbulb.fill")
                        summaryCard(title: "Hemstatus", value: "Ej ansluten", symbol: "house.fill")
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dina rum")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(HEMMATheme.warmWhite)
                        ContentUnavailableView(
                            "Inga rum ännu",
                            systemImage: "door.left.hand.open",
                            description: Text("Anslut till Apple Hem för att läsa in dina rum.")
                        )
                        .frame(minHeight: 190)
                        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))
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
}

#Preview {
    DashboardView()
}