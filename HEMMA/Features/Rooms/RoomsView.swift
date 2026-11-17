import SwiftUI
import HomeKit

struct RoomsView: View {
    @StateObject private var store = HomeKitStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Alla rum")
                        .font(.largeTitle.bold())
                        .foregroundStyle(HEMMATheme.warmWhite)
                    if store.isLoading {
                        messageCard("Ansluter till Apple Hem", detail: "Hämtar dina rum.")
                    } else if store.homes.isEmpty {
                        messageCard("Inga rum hittades", detail: "Kontrollera att ditt hem är konfigurerat i Apples Hem-app.")
                    } else {
                        ForEach(store.homes, id: \.uniqueIdentifier) { home in
                            ForEach(home.rooms, id: \.uniqueIdentifier) { room in
                                NavigationLink {
                                    RoomDetailView(room: room, store: store)
                                } label: {
                                    roomCard(room)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(HEMMATheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func roomCard(_ room: HMRoom) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "lamp.ceiling.fill")
                .font(.title2)
                .foregroundStyle(HEMMATheme.amber)
                .frame(width: 48, height: 48)
                .background(HEMMATheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 5) {
                Text(room.name)
                    .font(.headline)
                    .foregroundStyle(HEMMATheme.warmWhite)
                Text("\(room.accessories.filter(store.isLight).count) lampor")
                    .font(.caption)
                    .foregroundStyle(HEMMATheme.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(HEMMATheme.secondaryText)
        }
        .padding(16)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))
    }

    private func messageCard(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.headline).foregroundStyle(HEMMATheme.warmWhite)
            Text(detail).font(.subheadline).foregroundStyle(HEMMATheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))
    }
}

private struct RoomDetailView: View {
    let room: HMRoom
    @ObservedObject var store: HomeKitStore

    private var lights: [HMAccessory] { room.accessories.filter(store.isLight) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(room.name)
                    .font(.largeTitle.bold())
                    .foregroundStyle(HEMMATheme.warmWhite)
                if lights.isEmpty {
                    Text("Inga lampor i det här rummet ännu.")
                        .foregroundStyle(HEMMATheme.secondaryText)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))
                } else {
                    ForEach(lights, id: \.uniqueIdentifier) { accessory in
                        LightControlCard(accessory: accessory, store: store)
                    }
                }
                if let error = store.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 4)
                }
            }
            .padding(20)
        }
        .background(HEMMATheme.background.ignoresSafeArea())
        .toolbar(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct LightControlCard: View {
    let accessory: HMAccessory
    @ObservedObject var store: HomeKitStore
    @State private var brightnessValue: Double = 50

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(HEMMATheme.amber)
                VStack(alignment: .leading, spacing: 3) {
                    Text(accessory.name)
                        .font(.headline)
                        .foregroundStyle(HEMMATheme.warmWhite)
                    Text(accessory.isReachable ? "Tillgänglig" : "Kan inte nås")
                        .font(.caption)
                        .foregroundStyle(accessory.isReachable ? HEMMATheme.secondaryText : .red)
                }
                Spacer()
                if let state = store.powerState(for: accessory) {
                    Toggle("Lampa", isOn: Binding(
                        get: { state },
                        set: { store.setPower($0, for: accessory) }
                    ))
                    .labelsHidden()
                    .tint(HEMMATheme.amber)
                } else {
                    Text("Okänd status")
                        .font(.caption)
                        .foregroundStyle(HEMMATheme.secondaryText)
                }
            }
            if store.brightnessCharacteristic(for: accessory) != nil {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Ljusstyrka")
                            .font(.subheadline)
                            .foregroundStyle(HEMMATheme.secondaryText)
                        Spacer()
                        Text("\(Int(brightnessValue.rounded())) %")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(HEMMATheme.warmWhite)
                    }
                    Slider(value: $brightnessValue, in: 0...100) { editing in
                        if !editing { store.setBrightness(brightnessValue, for: accessory) }
                    }
                    .tint(HEMMATheme.amber)
                    .disabled(!accessory.isReachable)
                    .onAppear {
                        brightnessValue = store.brightness(for: accessory) ?? 50
                    }
                }
            }
        }
        .padding(18)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))
    }
}
