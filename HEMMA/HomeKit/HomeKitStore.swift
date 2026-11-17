import Combine
import Foundation
import HomeKit

@MainActor
final class HomeKitStore: NSObject, ObservableObject, HMHomeManagerDelegate, HMAccessoryDelegate {
    @Published private(set) var homes: [HMHome] = []
    @Published private(set) var isAuthorized = false
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?
    @Published private(set) var revision = 0
    @Published private(set) var pendingPowerAccessoryIDs: Set<UUID> = []
    @Published private(set) var pendingSceneIDs: Set<UUID> = []
    @Published private(set) var pendingCharacteristicIDs: Set<String> = []
    @Published private(set) var favoriteRoomIDs: Set<String> = UserDefaults.standard.stringArray(forKey: "hemma.favoriteRoomIDs").map(Set.init) ?? []

    private let manager = HMHomeManager()
    private var queuedCharacteristicWrites: [String: (value: NSNumber, characteristic: HMCharacteristic, accessory: HMAccessory, feature: String)] = [:]

    override init() {
        super.init()
        manager.delegate = self
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        homes = manager.homes
        homes.flatMap(\.accessories).forEach { $0.delegate = self }
        pruneDeletedFavoriteRooms()
        isAuthorized = manager.authorizationStatus.contains(.authorized)
        isLoading = false
        errorMessage = isAuthorized ? nil : "HEMMA saknar behörighet till Apple Hem. Kontrollera appens integritetsinställningar."
        revision += 1
    }

    func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        refreshHomes(manager)
    }

    func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
        refreshHomes(manager)
    }

    func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        revision += 1
    }

    func accessory(_ accessory: HMAccessory, didUpdateReachability reachable: Bool) {
        revision += 1
    }

    private func refreshHomes(_ manager: HMHomeManager) {
        homes = manager.homes
        homes.flatMap(\.accessories).forEach { $0.delegate = self }
        pruneDeletedFavoriteRooms()
        isAuthorized = manager.authorizationStatus.contains(.authorized)
        errorMessage = isAuthorized ? nil : "HEMMA saknar behörighet till Apple Hem. Kontrollera appens integritetsinställningar."
        revision += 1
    }


    var scenes: [(home: HMHome, actionSet: HMActionSet)] {
        homes.flatMap { home in
            home.actionSets
                .filter { $0.actionSetType == HMActionSetTypeUserDefined }
                .map { (home: home, actionSet: $0) }
        }
    }

    func isScenePending(_ actionSet: HMActionSet) -> Bool {
        pendingSceneIDs.contains(actionSet.uniqueIdentifier)
    }

    func activate(_ actionSet: HMActionSet, in home: HMHome) {
        guard !isScenePending(actionSet) else { return }
        pendingSceneIDs.insert(actionSet.uniqueIdentifier)
        errorMessage = nil
        revision += 1

        home.executeActionSet(actionSet) { [weak self] error in
            Task { @MainActor in
                self?.pendingSceneIDs.remove(actionSet.uniqueIdentifier)
                if let error {
                    self?.errorMessage = "Kunde inte starta \(actionSet.name): \(error.localizedDescription)"
                }
                self?.revision += 1
            }
        }
    }

    func refresh() {
        // HomeKit keeps HMHomeManager synchronized automatically; refresh the
        // published snapshot from its current state instead of calling a
        // nonexistent reload API.
        isLoading = true
        homes = manager.homes
        homes.flatMap(\.accessories).forEach { $0.delegate = self }
        isAuthorized = manager.authorizationStatus.contains(.authorized)
        isLoading = false
        errorMessage = isAuthorized ? nil : "HEMMA saknar behörighet till Apple Hem. Kontrollera appens integritetsinställningar."
        revision += 1
    }

    private func pruneDeletedFavoriteRooms() {
        let existingRoomIDs = Set(homes.flatMap(\.rooms).map { $0.uniqueIdentifier.uuidString })
        let retainedIDs = favoriteRoomIDs.intersection(existingRoomIDs)
        guard retainedIDs != favoriteRoomIDs else { return }
        favoriteRoomIDs = retainedIDs
        UserDefaults.standard.set(Array(retainedIDs), forKey: "hemma.favoriteRoomIDs")
    }

    func isFavorite(_ room: HMRoom) -> Bool {
        favoriteRoomIDs.contains(room.uniqueIdentifier.uuidString)
    }

    func toggleFavorite(_ room: HMRoom) {
        let id = room.uniqueIdentifier.uuidString
        if favoriteRoomIDs.contains(id) {
            favoriteRoomIDs.remove(id)
        } else {
            favoriteRoomIDs.insert(id)
        }
        UserDefaults.standard.set(Array(favoriteRoomIDs), forKey: "hemma.favoriteRoomIDs")
        revision += 1
    }

    func lightsAreOn(in room: HMRoom) -> Bool? {
        let lights = room.accessories.filter(isLight)
        guard !lights.isEmpty, lights.allSatisfy(\.isReachable) else { return nil }
        let states = lights.compactMap(powerState(for:))
        guard states.count == lights.count else { return nil }
        return states.allSatisfy { $0 }
    }

    func setLights(in room: HMRoom, isOn: Bool) {
        let roomLights = room.accessories.filter(isLight)
        let availableLights = roomLights.filter {
            $0.isReachable &&
            !isPowerCommandPending(for: $0) &&
            powerCharacteristic(for: $0) != nil
        }
        guard !availableLights.isEmpty else {
            errorMessage = "Inga tillgängliga lampor kan styras i det här rummet just nu."
            revision += 1
            return
        }
        availableLights.forEach { setPower(isOn, for: $0) }
        let skippedCount = roomLights.count - availableLights.count
        if skippedCount > 0 {
            errorMessage = "\(skippedCount) av \(roomLights.count) lampor kunde inte styras. Kontrollera att de är nåbara och inte redan håller på att ändras."
            revision += 1
        }
    }

    var favoriteRooms: [HMRoom] {
        homes.flatMap(visibleRooms(in:)).filter(isFavorite)
    }

    /// A hub-only assignment (for example an Apple TV named Hemmabio) is not a room to navigate.
    func isHomeHubAccessory(_ accessory: HMAccessory) -> Bool {
        accessory.category.categoryType == HMAccessoryCategoryTypeTelevision
    }

    func visibleRooms(in home: HMHome) -> [HMRoom] {
        home.rooms.filter { room in
            !room.accessories.isEmpty && !room.accessories.allSatisfy(isHomeHubAccessory)
        }
    }

    var roomCount: Int {
        homes.reduce(0) { $0 + visibleRooms(in: $1).count }
    }

    var lightAccessories: [HMAccessory] {
        homes.flatMap(\.accessories).filter(isLight)
    }

    /// Current indoor readings exposed by HomeKit temperature-sensor services.
    /// Values remain tied to their actual accessory and room; no synthetic rooms or averages.
    var temperatureReadings: [(accessory: HMAccessory, roomName: String, celsius: Double)] {
        homes.flatMap(\.accessories).compactMap { accessory in
            guard let service = accessory.services.first(where: { $0.serviceType == HMServiceTypeTemperatureSensor }),
                  let characteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentTemperature }),
                  let value = characteristic.value as? NSNumber else { return nil }
            return (accessory, accessory.room?.name ?? "Hela hemmet", value.doubleValue)
        }
        .sorted { $0.roomName.localizedCaseInsensitiveCompare($1.roomName) == .orderedAscending }
    }

    var homeHubStatus: String {
        guard let home = homes.first else { return "Inväntar hem" }
        switch home.homeHubState {
        case .connected: return "Ansluten"
        case .disconnected: return "Frånkopplad"
        case .notAvailable: return "Ingen hemhubb"
        @unknown default: return "Okänd status"
        }
    }

    func isLight(_ accessory: HMAccessory) -> Bool {
        accessory.services.contains { $0.serviceType == HMServiceTypeLightbulb }
    }

    func powerCharacteristic(for accessory: HMAccessory) -> HMCharacteristic? {
        characteristic(for: accessory, type: HMCharacteristicTypePowerState)
    }

    func brightnessCharacteristic(for accessory: HMAccessory) -> HMCharacteristic? {
        characteristic(for: accessory, type: HMCharacteristicTypeBrightness)
    }

    func colorTemperatureCharacteristic(for accessory: HMAccessory) -> HMCharacteristic? {
        characteristic(for: accessory, type: HMCharacteristicTypeColorTemperature)
    }

    func hueCharacteristic(for accessory: HMAccessory) -> HMCharacteristic? {
        characteristic(for: accessory, type: HMCharacteristicTypeHue)
    }

    func saturationCharacteristic(for accessory: HMAccessory) -> HMCharacteristic? {
        characteristic(for: accessory, type: HMCharacteristicTypeSaturation)
    }

    func colorTemperatureKelvin(for accessory: HMAccessory) -> Double? {
        guard let value = colorTemperatureCharacteristic(for: accessory)?.value as? NSNumber else { return nil }
        let mireds = value.doubleValue
        guard mireds > 0 else { return nil }
        return 1_000_000 / mireds
    }

    func hue(for accessory: HMAccessory) -> Double? {
        (hueCharacteristic(for: accessory)?.value as? NSNumber)?.doubleValue
    }

    func saturation(for accessory: HMAccessory) -> Double? {
        (saturationCharacteristic(for: accessory)?.value as? NSNumber)?.doubleValue
    }

    func setColorTemperature(kelvin: Double, for accessory: HMAccessory) {
        let mireds = Int((1_000_000 / min(max(kelvin, 2000), 6500)).rounded())
        write(NSNumber(value: mireds), to: colorTemperatureCharacteristic(for: accessory), accessory: accessory, feature: "färgtemperatur")
    }

    func setHue(_ value: Double, for accessory: HMAccessory) {
        write(NSNumber(value: min(max(value, 0), 360)), to: hueCharacteristic(for: accessory), accessory: accessory, feature: "färg")
    }

    func setSaturation(_ value: Double, for accessory: HMAccessory) {
        write(NSNumber(value: min(max(value, 0), 100)), to: saturationCharacteristic(for: accessory), accessory: accessory, feature: "färgmättnad")
    }

    func isCharacteristicPending(for accessory: HMAccessory, type: String) -> Bool {
        pendingCharacteristicIDs.contains("\(accessory.uniqueIdentifier.uuidString):\(type)")
    }

    private func write(_ value: NSNumber, to characteristic: HMCharacteristic?, accessory: HMAccessory, feature: String) {
        guard accessory.isReachable, let characteristic else {
            errorMessage = "\(accessory.name) saknar stöd för \(feature) eller kan inte nås."
            revision += 1
            return
        }
        let commandID = "\(accessory.uniqueIdentifier.uuidString):\(characteristic.characteristicType)"
        if pendingCharacteristicIDs.contains(commandID) {
            // Preserve the newest slider value while HomeKit acknowledges the previous write.
            queuedCharacteristicWrites[commandID] = (value, characteristic, accessory, feature)
            return
        }
        errorMessage = nil
        pendingCharacteristicIDs.insert(commandID)
        revision += 1
        characteristic.writeValue(value) { [weak self] error in
            Task { @MainActor in
                self?.pendingCharacteristicIDs.remove(commandID)
                if let error {
                    self?.errorMessage = "Kunde inte ändra \(feature) på \(accessory.name): \(error.localizedDescription)"
                    self?.queuedCharacteristicWrites.removeValue(forKey: commandID)
                } else if let queued = self?.queuedCharacteristicWrites.removeValue(forKey: commandID) {
                    self?.write(queued.value, to: queued.characteristic, accessory: queued.accessory, feature: queued.feature)
                }
                self?.revision += 1
            }
        }
    }

    func powerState(for accessory: HMAccessory) -> Bool? {
        guard let value = powerCharacteristic(for: accessory)?.value else { return nil }
        return value as? Bool
    }

    func brightness(for accessory: HMAccessory) -> Double? {
        guard let value = brightnessCharacteristic(for: accessory)?.value else { return nil }
        return (value as? NSNumber)?.doubleValue
    }

    var allLightsAreOn: Bool? {
        let lights = lightAccessories
        guard !lights.isEmpty, lights.allSatisfy(\.isReachable) else { return nil }
        let states = lights.compactMap(powerState(for:))
        guard states.count == lights.count else { return nil }
        return states.allSatisfy { $0 }
    }

    func setAllLights(_ isOn: Bool) {
        let lights = lightAccessories
        let availableLights = lights.filter {
            $0.isReachable &&
            !isPowerCommandPending(for: $0) &&
            powerCharacteristic(for: $0) != nil
        }

        guard !availableLights.isEmpty else {
            errorMessage = "Inga tillgängliga lampor kan styras just nu."
            revision += 1
            return
        }

        availableLights.forEach { setPower(isOn, for: $0) }
        let skippedCount = lights.count - availableLights.count
        if skippedCount > 0 {
            errorMessage = "\(skippedCount) av \(lights.count) lampor kunde inte styras. Kontrollera att de är nåbara och inte redan håller på att ändras."
            revision += 1
        }
    }

    func isPowerCommandPending(for accessory: HMAccessory) -> Bool {
        pendingPowerAccessoryIDs.contains(accessory.uniqueIdentifier)
    }

    func setPower(_ isOn: Bool, for accessory: HMAccessory) {
        guard !isPowerCommandPending(for: accessory) else { return }
        guard accessory.isReachable, let characteristic = powerCharacteristic(for: accessory) else {
            errorMessage = "\(accessory.name) kan inte nås just nu."
            revision += 1
            return
        }
        errorMessage = nil
        pendingPowerAccessoryIDs.insert(accessory.uniqueIdentifier)
        revision += 1
        characteristic.writeValue(isOn) { [weak self] error in
            Task { @MainActor in
                self?.pendingPowerAccessoryIDs.remove(accessory.uniqueIdentifier)
                if let error {
                    self?.errorMessage = "Kunde inte styra \(accessory.name): \(error.localizedDescription)"
                }
                self?.revision += 1
            }
        }
    }

    func setBrightness(_ value: Double, for accessory: HMAccessory) {
        guard accessory.isReachable, let characteristic = brightnessCharacteristic(for: accessory) else {
            errorMessage = "\(accessory.name) saknar stöd för dimring eller kan inte nås."
            revision += 1
            return
        }
        write(NSNumber(value: Int(min(max(value, 0), 100).rounded())), to: characteristic, accessory: accessory, feature: "ljusstyrka")
    }

    private func characteristic(for accessory: HMAccessory, type: String) -> HMCharacteristic? {
        accessory.services
            .flatMap(\.characteristics)
            .first { $0.characteristicType == type }
    }
}
