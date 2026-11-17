import SwiftUI
import HomeKit

struct DashboardView: View {
    @EnvironmentObject private var homeStore: HomeKitStore

    private var allRooms: [HMRoom] {
        homeStore.homes.flatMap { $0.rooms }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var lightsOnCount: Int {
        homeStore.lightAccessories.filter { homeStore.powerState(for: $0) == true }.count
    }

    private var scenes: [(home: HMHome, actionSet: HMActionSet)] {
        Array(homeStore.scenes.prefix(4))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                    header
                    heroCard
                    statusMetrics
                    quickLightingCard
                    roomsSection
                    scenesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 34)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .background(HEMMATheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .background(HEMMATheme.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Circle().fill(HEMMATheme.amber).frame(width: 6, height: 6)
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.8)
                    .foregroundStyle(HEMMATheme.secondaryText)
                Spacer()
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(HEMMATheme.warmWhite)
                    .frame(width: 42, height: 42)
                    .background(HEMMATheme.surface, in: Circle())
            }
            Text("HEMMA")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .tracking(-1.1)
                .foregroundStyle(HEMMATheme.warmWhite)
            Text("Allt hemma. Under kontroll.")
                .font(.system(size: 16))
                .foregroundStyle(HEMMATheme.secondaryText)
        }
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.30, green: 0.27, blue: 0.24),
                    Color(red: 0.15, green: 0.17, blue: 0.19),
                    Color(red: 0.07, green: 0.09, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(HEMMATheme.amber.opacity(0.16))
                        .frame(width: 190, height: 190)
                        .blur(radius: 38)
                        .offset(x: proxy.size.width * 0.46, y: -30)
                    Image(systemName: "house.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white.opacity(0.055))
                        .frame(width: 230, height: 190)
                        .offset(x: proxy.size.width * 0.28, y: 12)
                    Image(systemName: "lightbulb.2.fill")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(HEMMATheme.amber.opacity(0.72))
                        .offset(x: proxy.size.width * 0.70, y: -proxy.size.height * 0.23)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 7) {
                Label(homeStore.isAuthorized ? "HEMMET ÄR ANSLUTET" : "ANSLUTER TILL DITT HEM", systemImage: "house")
                    .font(.caption2.weight(.bold))
                    .tracking(1.3)
                    .foregroundStyle(HEMMATheme.amber)
                Text(greeting)
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(heroSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.76))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 10 { return "God morgon" }
        if hour < 18 { return "Välkommen hem" }
        return "God kväll"
    }

    private var heroSubtitle: String {
        guard homeStore.isAuthorized else {
            return homeStore.errorMessage ?? "Väntar på anslutning till Apple Hem."
        }
        let on = lightsOnCount
        let total = homeStore.lightAccessories.count
        return total == 0 ? "Ditt hem är redo när du är det." : "\(on) av \(total) lampor lyser just nu."
    }

    private var statusMetrics: some View {
        HStack(spacing: 11) {
            metricCard(value: homeStore.isAuthorized ? "\(homeStore.lightAccessories.count)" : "—", title: "Lampor", symbol: "lightbulb.fill", detail: homeStore.isAuthorized ? "\(lightsOnCount) tända" : "Ansluter")
            metricCard(value: homeStore.isAuthorized ? "\(homeStore.roomCount)" : "—", title: "Rum", symbol: "square.grid.2x2.fill", detail: "I ditt hem")
            metricCard(value: homeStore.isAuthorized ? "\(scenes.count)" : "—", title: "Scener", symbol: "sparkles", detail: "Snabbval")
        }
    }

    private func metricCard(value: String, title: String, symbol: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(HEMMATheme.amber)
            Text(value)
                .font(.system(size: 27, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(HEMMATheme.warmWhite)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(HEMMATheme.warmWhite)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(HEMMATheme.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .strokeBorder(.white.opacity(0.035), lineWidth: 1)
        }
    }

    private var quickLightingCard: some View {
        Button {
            homeStore.setAllLights(homeStore.allLightsAreOn != true)
        } label: {
            HStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(HEMMATheme.amber.opacity(0.15))
                        .frame(width: 58, height: 58)
                    Image(systemName: homeStore.allLightsAreOn == true ? "lightbulb.slash.fill" : "lightbulb.2.fill")
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(HEMMATheme.amber)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(homeStore.allLightsAreOn == true ? "Släck alla lampor" : "Tänd alla lampor")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(HEMMATheme.warmWhite)
                    Text("Styr belysningen i hela hemmet")
                        .font(.caption)
                        .foregroundStyle(HEMMATheme.secondaryText)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HEMMATheme.amber)
            }
            .padding(17)
            .background(
                LinearGradient(colors: [HEMMATheme.elevatedSurface, HEMMATheme.surface], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 23, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .strokeBorder(HEMMATheme.amber.opacity(0.13), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!homeStore.isAuthorized || !homeStore.lightAccessories.contains { $0.isReachable } || !homeStore.pendingPowerAccessoryIDs.isEmpty)
    }

    private var roomsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Favoritrum", subtitle: "Dina viktigaste rum", action: "Alla rum")
            if !homeStore.favoriteRooms.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(homeStore.favoriteRooms, id: \HMRoom.uniqueIdentifier) { room in
                            roomTile(room)
                        }
                    }
                    .padding(.vertical, 2)
                }
            } else if !allRooms.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(allRooms.prefix(5)), id: \.uniqueIdentifier) { room in
                            roomTile(room)
                        }
                    }
                    .padding(.vertical, 2)
                }
            } else {
                emptyRoomsCard
            }
        }
    }

    private func roomTile(_ room: HMRoom) -> some View {
        NavigationLink {
            RoomDetailView(room: room, store: homeStore)
        } label: {
            ZStack(alignment: .bottomLeading) {
                roomGradient(for: room.name)
                Image(systemName: roomSymbol(for: room.name))
                    .font(.system(size: 62, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.20))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(14)
                LinearGradient(colors: [.clear, .black.opacity(0.78)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 5) {
                    Text(room.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(room.accessories.filter(homeStore.isLight).count) lampor")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                }
                .padding(14)
            }
            .frame(width: 166, height: 142)
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .strokeBorder(.white.opacity(0.09), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var emptyRoomsCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "door.left.hand.open").font(.title2).foregroundStyle(HEMMATheme.amber)
            Text(homeStore.isAuthorized ? "Dina rum visas här när de har hittats i Apple Hem." : "Anslut till Apple Hem för att visa dina rum.")
                .font(.subheadline)
                .foregroundStyle(HEMMATheme.secondaryText)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var scenesSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeader("Scener", subtitle: "Stämning med ett tryck", action: "Visa alla")
            if scenes.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles").font(.title2).foregroundStyle(HEMMATheme.amber)
                    Text("Dina Apple Hem-scener visas här när de finns tillgängliga.")
                        .font(.subheadline)
                        .foregroundStyle(HEMMATheme.secondaryText)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: 20))
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Array(scenes.enumerated()), id: \.offset) { _, item in
                        Button {
                            homeStore.activate(item.actionSet, in: item.home)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(HEMMATheme.amber)
                                Text(item.actionSet.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(HEMMATheme.warmWhite)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                if homeStore.isScenePending(item.actionSet) {
                                    ProgressView().tint(HEMMATheme.amber)
                                }
                            }
                            .padding(13)
                            .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .disabled(homeStore.isScenePending(item.actionSet))
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String, subtitle: String, action: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(HEMMATheme.warmWhite)
                Spacer()
                Text(action)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HEMMATheme.amber)
            }
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(HEMMATheme.secondaryText)
        }
    }

    private func roomGradient(for name: String) -> LinearGradient {
        let key = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let colors: [Color]
        if key.contains("kok") {
            colors = [Color(red: 0.45, green: 0.28, blue: 0.16), Color(red: 0.13, green: 0.11, blue: 0.10)]
        } else if key.contains("vard") || key.contains("living") {
            colors = [Color(red: 0.26, green: 0.35, blue: 0.36), Color(red: 0.10, green: 0.15, blue: 0.17)]
        } else if key.contains("sov") || key.contains("bed") {
            colors = [Color(red: 0.25, green: 0.28, blue: 0.42), Color(red: 0.10, green: 0.11, blue: 0.18)]
        } else {
            colors = [Color(red: 0.34, green: 0.29, blue: 0.23), Color(red: 0.12, green: 0.12, blue: 0.13)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func roomSymbol(for name: String) -> String {
        let key = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if key.contains("kok") { return "fork.knife" }
        if key.contains("sov") || key.contains("bed") { return "bed.double.fill" }
        if key.contains("bad") || key.contains("bath") { return "shower.fill" }
        if key.contains("hall") { return "door.left.hand.open" }
        return "sofa.fill"
    }
}
