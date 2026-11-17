import SwiftUI
import HomeKit

struct RoomsView: View {
    @EnvironmentObject private var store: HomeKitStore
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 23) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("DITT HEM")
                            .font(.caption.weight(.bold))
                            .tracking(1.7)
                            .foregroundStyle(HEMMATheme.amber)
                        Text("Rum")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .tracking(-0.8)
                            .foregroundStyle(HEMMATheme.warmWhite)
                        Text("Varje rum, precis där du behöver det.")
                            .font(.subheadline)
                            .foregroundStyle(HEMMATheme.secondaryText)
                    }

                    if store.isLoading {
                        messageCard("Ansluter till Apple Hem", detail: "Hämtar dina rum.")
                    } else if !store.isAuthorized {
                        messageCard("Åtkomst till Apple Hem saknas", detail: "Tillåt HEMMA att komma åt ditt hem i iPhone-inställningarna och försök igen.")
                    } else if store.homes.isEmpty {
                        messageCard("Inga rum hittades", detail: "Kontrollera att ditt hem är konfigurerat i Apples Hem-app.")
                    } else {
                        ForEach(store.homes, id: \.uniqueIdentifier) { home in
                            VStack(alignment: .leading, spacing: 13) {
                                HStack {
                                    Text(home.name)
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(HEMMATheme.warmWhite)
                                    Spacer()
                                    Text("\(store.visibleRooms(in: home).count) RUM")
                                        .font(.caption2.weight(.bold))
                                        .tracking(1.1)
                                        .foregroundStyle(HEMMATheme.secondaryText)
                                }
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(store.visibleRooms(in: home), id: \.uniqueIdentifier) { room in
                                        roomTile(room)
                                    }
                                }
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

    private func roomTile(_ room: HMRoom) -> some View {
        NavigationLink {
            RoomDetailView(room: room, store: store)
        } label: {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: RoomPhotography.image(for: room.name)) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default: roomGradient(for: room.name)
                    }
                }
                .frame(height: 158)
                .clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.78)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 5) {
                    Text(room.name).font(.headline.weight(.semibold)).foregroundStyle(.white).lineLimit(1)
                    HStack(spacing: 5) {
                        Image(systemName: "lightbulb.fill").font(.caption2)
                        Text("\(room.accessories.filter(store.isLight).count) lampor").font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.82))
                }
                .padding(14)
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            store.toggleFavorite(room)
                        } label: {
                            Image(systemName: store.isFavorite(room) ? "star.fill" : "star")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(store.isFavorite(room) ? HEMMATheme.amber : .white)
                                .frame(width: 32, height: 32)
                                .background(.black.opacity(0.38), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(store.isFavorite(room) ? "Ta bort favorit" : "Lägg till favorit")
                    }
                    Spacer()
                }
                .padding(10)
            }
            .frame(height: 158)
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.22), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }

    private func roomGradient(for name: String) -> LinearGradient {
        let key = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let colors: [Color]
        if key.contains("kok") {
            colors = [Color(red: 0.47, green: 0.29, blue: 0.17), Color(red: 0.13, green: 0.10, blue: 0.09)]
        } else if key.contains("vard") || key.contains("living") {
            colors = [Color(red: 0.28, green: 0.38, blue: 0.38), Color(red: 0.09, green: 0.14, blue: 0.16)]
        } else if key.contains("sov") || key.contains("bed") {
            colors = [Color(red: 0.28, green: 0.31, blue: 0.46), Color(red: 0.09, green: 0.10, blue: 0.17)]
        } else if key.contains("bad") || key.contains("bath") {
            colors = [Color(red: 0.22, green: 0.38, blue: 0.42), Color(red: 0.08, green: 0.13, blue: 0.16)]
        } else {
            colors = [Color(red: 0.38, green: 0.32, blue: 0.25), Color(red: 0.12, green: 0.12, blue: 0.13)]
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

    private func messageCard(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.headline).foregroundStyle(HEMMATheme.warmWhite)
            Text(detail).font(.subheadline).foregroundStyle(HEMMATheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct RoomDetailView: View {
    let room: HMRoom
    @ObservedObject var store: HomeKitStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLightID: UUID?
    private var selectedLight: HMAccessory? {
        lights.first(where: { $0.uniqueIdentifier == selectedLightID }) ?? lights.first
    }
    private var lights: [HMAccessory] { room.accessories.filter(store.isLight) }

    private var roomLightingTitle: String {
        switch store.lightsAreOn(in: room) {
        case .some(true): return "Släck alla lampor"
        case .some(false): return "Tänd alla lampor"
        case .none: return "Tänd tillgängliga lampor"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: RoomPhotography.image(for: room.name)) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFill()
                        default: LinearGradient(colors: [HEMMATheme.elevatedSurface, HEMMATheme.background], startPoint: .topLeading, endPoint: .bottomTrailing)
                        }
                    }
                    .frame(height: 205)
                    .clipped()
                    LinearGradient(colors: [.clear, .black.opacity(0.76)], startPoint: .center, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("RUMSKONTROLL")
                            .font(.caption.weight(.bold))
                            .tracking(1.5)
                            .foregroundStyle(HEMMATheme.amber)
                        Text(room.name)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("\(lights.count) lampor · Apple Hem")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.82))
                    }
                    .padding(20)
                }
                .frame(height: 205)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                }

                Button {
                    store.setLights(in: room, isOn: store.lightsAreOn(in: room) != true)
                } label: {
                    HStack(spacing: 13) {
                        Image(systemName: store.lightsAreOn(in: room) == true ? "lightbulb.slash.fill" : "lightbulb.2.fill")
                            .font(.title2)
                            .foregroundStyle(HEMMATheme.background)
                            .frame(width: 48, height: 48)
                            .background(HEMMATheme.amber, in: RoundedRectangle(cornerRadius: 15))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(roomLightingTitle)
                                .font(.headline)
                                .foregroundStyle(HEMMATheme.warmWhite)
                            Text("Styr rummets tillgängliga lampor")
                                .font(.caption)
                                .foregroundStyle(HEMMATheme.secondaryText)
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundStyle(HEMMATheme.amber)
                    }
                    .padding(15)
                    .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                .disabled(!lights.contains(where: \.isReachable) || lights.contains(where: store.isPowerCommandPending(for:)))

                if !lights.isEmpty {
                    VStack(alignment: .leading, spacing: 13) {
                        HStack {
                            Text("LJUS I RUMMET")
                                .font(.caption.weight(.bold))
                                .tracking(1.4)
                                .foregroundStyle(HEMMATheme.amber)
                            Spacer()
                            Text("\(lights.filter { store.powerState(for: $0) == true }.count) av \(lights.count) tända")
                                .font(.caption)
                                .foregroundStyle(HEMMATheme.secondaryText)
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(lights, id: \.uniqueIdentifier) { accessory in
                                roomLightButton(accessory)
                            }
                        }
                    }

                    if let selectedLight, store.brightnessCharacteristic(for: selectedLight) != nil {
                        CircularBrightnessPanel(accessory: selectedLight, store: store)
                    } else if let selectedLight {
                        LightControlCard(accessory: selectedLight, store: store)
                    }
                } else {
                    Text("Inga lampor i det här rummet ännu.")
                        .font(.subheadline)
                        .foregroundStyle(HEMMATheme.secondaryText)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: 18))
                }

                if let error = store.errorMessage {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
            .padding(20)
            .padding(.bottom, 30)
        }
        .background(HEMMATheme.background.ignoresSafeArea())
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar(.visible, for: .navigationBar)
    }

    private func roomLightButton(_ accessory: HMAccessory) -> some View {
        let isSelected = selectedLight?.uniqueIdentifier == accessory.uniqueIdentifier
        let isOn = store.powerState(for: accessory) == true
        return Button {
            if selectedLightID == accessory.uniqueIdentifier {
                if accessory.isReachable, store.powerState(for: accessory) != nil,
                   !store.isPowerCommandPending(for: accessory) {
                    store.setPower(!isOn, for: accessory)
                }
            } else {
                selectedLightID = accessory.uniqueIdentifier
            }
        } label: {
            VStack(spacing: 9) {
                Image(systemName: isOn ? "lightbulb.fill" : "lightbulb")
                    .font(.system(size: 23, weight: .medium))
                    .foregroundStyle(isOn ? HEMMATheme.amber : HEMMATheme.secondaryText)
                    .frame(height: 28)
                Text(accessory.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HEMMATheme.warmWhite)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(isOn ? "På" : "Av")
                    .font(.caption2)
                    .foregroundStyle(isOn ? HEMMATheme.amber : HEMMATheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 6)
            .background(isSelected ? HEMMATheme.amber.opacity(0.13) : HEMMATheme.surface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .strokeBorder(isSelected ? HEMMATheme.amber.opacity(0.8) : Color.white.opacity(0.05), lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!accessory.isReachable || store.isPowerCommandPending(for: accessory))
        .accessibilityLabel("\(accessory.name), \(isOn ? "på" : "av"). Välj lampan, tryck igen för att växla.")
    }

    private var roomSymbol: String {
        let key = room.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if key.contains("kok") { return "fork.knife" }
        if key.contains("sov") || key.contains("bed") { return "bed.double.fill" }
        if key.contains("bad") { return "shower.fill" }
        if key.contains("hall") { return "door.left.hand.open" }
        return "sofa.fill"
    }
}

struct LightControlCard: View {
    let accessory: HMAccessory
    @ObservedObject var store: HomeKitStore
    @State private var brightnessValue: Double = 50
    @State private var temperatureValue: Double = 2700
    @State private var hueValue: Double = 0
    @State private var saturationValue: Double = 100
    @State private var editingBrightness = false
    @State private var editingTemperature = false
    @State private var editingHue = false
    @State private var editingSaturation = false

    private var isOn: Bool { store.powerState(for: accessory) == true }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                guard accessory.isReachable, store.powerState(for: accessory) != nil else { return }
                store.setPower(!isOn, for: accessory)
            } label: {
                HStack(spacing: 13) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isOn ? HEMMATheme.amber.opacity(0.16) : HEMMATheme.elevatedSurface)
                            .frame(width: 50, height: 50)
                        Image(systemName: isOn ? "lightbulb.fill" : "lightbulb")
                            .font(.title2)
                            .foregroundStyle(isOn ? HEMMATheme.amber : HEMMATheme.secondaryText)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(accessory.name)
                            .font(.headline)
                            .foregroundStyle(HEMMATheme.warmWhite)
                        Text(!accessory.isReachable ? "Kan inte nås" : (isOn ? "Tänd · Tryck för att släcka" : "Släckt · Tryck för att tända"))
                            .font(.caption)
                            .foregroundStyle(accessory.isReachable ? HEMMATheme.secondaryText : .red)
                    }
                    Spacer()
                    if store.isPowerCommandPending(for: accessory) {
                        ProgressView().tint(HEMMATheme.amber)
                    } else {
                        Image(systemName: isOn ? "power.circle.fill" : "power.circle")
                            .font(.system(size: 32))
                            .foregroundStyle(isOn ? HEMMATheme.amber : HEMMATheme.secondaryText)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!accessory.isReachable || store.powerState(for: accessory) == nil || store.isPowerCommandPending(for: accessory))

            if store.brightnessCharacteristic(for: accessory) != nil {
                controlSlider(title: "Ljusstyrka", type: HMCharacteristicTypeBrightness, value: $brightnessValue, isEditing: $editingBrightness, range: 0...100, suffix: "%") { store.setBrightness($0, for: accessory) }
            }
            if store.colorTemperatureCharacteristic(for: accessory) != nil {
                controlSlider(title: "Färgtemperatur", type: HMCharacteristicTypeColorTemperature, value: $temperatureValue, isEditing: $editingTemperature, range: 2000...6500, suffix: " K") { store.setColorTemperature(kelvin: $0, for: accessory) }
            }
            if store.hueCharacteristic(for: accessory) != nil, store.saturationCharacteristic(for: accessory) != nil {
                controlSlider(title: "Färgton", type: HMCharacteristicTypeHue, value: $hueValue, isEditing: $editingHue, range: 0...360, suffix: "°") { store.setHue($0, for: accessory) }
                controlSlider(title: "Färgmättnad", type: HMCharacteristicTypeSaturation, value: $saturationValue, isEditing: $editingSaturation, range: 0...100, suffix: "%") { store.setSaturation($0, for: accessory) }
            }
        }
        .padding(17)
        .background(HEMMATheme.surface, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .strokeBorder(isOn ? HEMMATheme.amber.opacity(0.16) : .white.opacity(0.035), lineWidth: 1)
        }
        .onAppear(perform: syncValues)
        .onChange(of: store.revision) { _, _ in syncValues() }
    }

    private func controlSlider(title: String, type: String, value: Binding<Double>, isEditing: Binding<Bool>, range: ClosedRange<Double>, suffix: String, onCommit: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title).font(.caption.weight(.medium)).foregroundStyle(HEMMATheme.secondaryText)
                Spacer()
                Text("\(Int(value.wrappedValue.rounded()))\(suffix)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(HEMMATheme.warmWhite)
            }
            Slider(value: value, in: range) { editing in
                isEditing.wrappedValue = editing
                if !editing { onCommit(value.wrappedValue) }
            }
            .tint(HEMMATheme.amber)
            .disabled(!accessory.isReachable)
        }
    }

    private func syncValues() {
        if !editingBrightness && !store.isCharacteristicPending(for: accessory, type: HMCharacteristicTypeBrightness) { brightnessValue = store.brightness(for: accessory) ?? brightnessValue }
        if !editingTemperature && !store.isCharacteristicPending(for: accessory, type: HMCharacteristicTypeColorTemperature) { temperatureValue = store.colorTemperatureKelvin(for: accessory) ?? temperatureValue }
        if !editingHue && !store.isCharacteristicPending(for: accessory, type: HMCharacteristicTypeHue) { hueValue = store.hue(for: accessory) ?? hueValue }
        if !editingSaturation && !store.isCharacteristicPending(for: accessory, type: HMCharacteristicTypeSaturation) { saturationValue = store.saturation(for: accessory) ?? saturationValue }
    }
}

private struct CircularBrightnessPanel: View {
    let accessory: HMAccessory
    @ObservedObject var store: HomeKitStore
    @State private var brightness: Double = 50
    @State private var isEditing = false

    private var isOn: Bool { store.powerState(for: accessory) == true }

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("LJUSSTYRKA")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(HEMMATheme.amber)
                Text(accessory.name)
                    .font(.headline)
                    .foregroundStyle(HEMMATheme.warmWhite)
                Spacer(minLength: 8)
                Text("\(Int(brightness.rounded()))%")
                    .font(.system(size: 38, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(HEMMATheme.warmWhite)
                Text(isOn ? "Lampan är tänd" : "Lampan är släckt")
                    .font(.caption)
                    .foregroundStyle(HEMMATheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Capsule()
                    .fill(HEMMATheme.background.opacity(0.85))
                    .frame(width: 48, height: 190)
                GeometryReader { geometry in
                    let trackHeight = geometry.size.height
                    ZStack(alignment: .bottom) {
                        Capsule()
                            .fill(HEMMATheme.elevatedSurface)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.78, blue: 0.43), HEMMATheme.amber],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: max(8, trackHeight * brightness / 100))
                    }
                    .frame(width: 8, height: trackHeight)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isEditing = true
                                let fraction = 1 - min(max(value.location.y / trackHeight, 0), 1)
                                brightness = fraction * 100
                            }
                            .onEnded { _ in
                                isEditing = false
                                store.setBrightness(brightness, for: accessory)
                            }
                    )
                }
                .frame(width: 48, height: 190)
                .padding(.vertical, 12)
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(HEMMATheme.warmWhite)
                    .offset(y: -112)
                    .allowsHitTesting(false)
            }
            .frame(width: 48, height: 214)
            .accessibilityElement()
            .accessibilityLabel("Ljusstyrka för \(accessory.name)")
            .accessibilityValue("\(Int(brightness.rounded())) procent")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: brightness = min(100, brightness + 5)
                case .decrement: brightness = max(0, brightness - 5)
                @unknown default: break
                }
                store.setBrightness(brightness, for: accessory)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [HEMMATheme.elevatedSurface, HEMMATheme.surface], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 25, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .strokeBorder(HEMMATheme.amber.opacity(0.15), lineWidth: 1)
        }
        .onAppear {
            brightness = store.brightness(for: accessory) ?? 50
        }
        .onChange(of: store.revision) { _, _ in
            guard !isEditing, !store.isCharacteristicPending(for: accessory, type: HMCharacteristicTypeBrightness) else { return }
            brightness = store.brightness(for: accessory) ?? brightness
        }
        .disabled(!accessory.isReachable)
    }
}
