import SwiftUI
import HomeKit

struct RoomsView: View {
    @EnvironmentObject private var store: HomeKitStore

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
                                HStack(spacing: 10) {
                                    NavigationLink {
                                        RoomDetailView(room: room, store: store)
                                    } label: {
                                        roomCard(room)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        store.toggleFavorite(room)
                                    } label: {
                                        Image(systemName: store.isFavorite(room) ? "star.fill" : "star")
                                            .font(.headline)
                                            .foregroundStyle(store.isFavorite(room) ? HEMMATheme.amber : HEMMATheme.secondaryText)
                                            .frame(width: 48, height: 58)
                                            .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: 15))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(store.isFavorite(room) ? "Ta bort favorit" : "Lägg till favorit")
                                }
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

    private var roomLightingButton: some View {
        Button {
            store.setLights(in: room, isOn: store.lightsAreOn(in: room) != true)
        } label: {
            Label(
                store.lightsAreOn(in: room) == true ? "Släck alla lampor i rummet" : "Tänd alla lampor i rummet",
                systemImage: store.lightsAreOn(in: room) == true ? "lightbulb.slash.fill" : "lightbulb.2.fill"
            )
            .font(.headline)
            .foregroundStyle(HEMMATheme.warmWhite)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(HEMMATheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!lights.contains(where: \.isReachable) || lights.contains(where: store.isPowerCommandPending(for:)))
    }

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
                    roomLightingButton
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
    @State private var temperatureValue: Double = 2700
    @State private var hueValue: Double = 0
    @State private var saturationValue: Double = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
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
                        get: { store.powerState(for: accessory) ?? state },
                        set: { store.setPower($0, for: accessory) }
                    ))
                    .labelsHidden()
                    .tint(HEMMATheme.amber)
                    .disabled(store.isPowerCommandPending(for: accessory))
                } else {
                    Text("Okänd status")
                        .font(.caption)
                        .foregroundStyle(HEMMATheme.secondaryText)
                }
            }

            if store.brightnessCharacteristic(for: accessory) != nil {
                controlSlider(title: "Ljusstyrka", value: $brightnessValue, range: 0...100, suffix: "%") { value in
                    store.setBrightness(value, for: accessory)
                }
            }

            if store.colorTemperatureCharacteristic(for: accessory) != nil {
                controlSlider(title: "Färgtemperatur", value: $temperatureValue, range: 2000...6500, suffix: " K") { value in
                    store.setColorTemperature(kelvin: value, for: accessory)
                }
            }

            if store.hueCharacteristic(for: accessory) != nil,
               store.saturationCharacteristic(for: accessory) != nil {
                controlSlider(title: "Färgton", value: $hueValue, range: 0...360, suffix: "°") { value in
                    store.setHue(value, for: accessory)
                }
                controlSlider(title: "Färgmättnad", value: $saturationValue, range: 0...100, suffix: "%") { value in
                    store.setSaturation(value, for: accessory)
                }
            }
        }
        .padding(18)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: HEMMATheme.cardRadius))
        .onAppear(perform: syncValues)
        .onChange(of: store.revision) { _, _ in syncValues() }
    }

    private func controlSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        suffix: String,
        onCommit: @escaping (Double) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(HEMMATheme.secondaryText)
                Spacer()
                Text("\(Int(value.wrappedValue.rounded()))\(suffix)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(HEMMATheme.warmWhite)
            }
            Slider(value: value, in: range) { editing in
                if !editing { onCommit(value.wrappedValue) }
            }
            .tint(HEMMATheme.amber)
            .disabled(!accessory.isReachable)
        }
    }

    private func syncValues() {
        brightnessValue = store.brightness(for: accessory) ?? brightnessValue
        temperatureValue = store.colorTemperatureKelvin(for: accessory) ?? temperatureValue
        hueValue = store.hue(for: accessory) ?? hueValue
        saturationValue = store.saturation(for: accessory) ?? saturationValue
    }
}
