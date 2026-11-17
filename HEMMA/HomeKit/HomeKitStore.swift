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
    @Published private(set) var favoriteRoomIDs: Set<String> = UserDefaults.standard.stringArray(forKey: "hemma.favoriteRoomIDs").map(Set.init) ?? []

    private let manager = HMHomeManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        homes = manager.homes
        homes.flatMap(\.accessories).forEach { $0.delegate = self }
        isAuthorized = true
        isLoading = false
        errorMessage = nil
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
        revision += 1
    }


    var scenes: [(home: HMHome, actionSet: HMActionSet)] {
        homes.flatMap { home in
            home.actionSets
                .filter { $0.actionSetType == HMActionSetTypeUserDefined }
                .map { (home: home, actionSet: $0) }
        }
    }

    func activate(_ actionSet: HMActionSet, in home: HMHome) {
        home.executeActionSet(actionSet) { [weak self] error in
            Task { @MainActor in
                if let error {
                    self?.errorMessage = "Kunde inte starta \\(actionSet.name): \\(error.localizedDescription)"
                } else {
                    self?.errorMessage = nil
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
        isAuthorized = true
        isLoading = false
        errorMessage = nil
        revision += 1
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

    var favoriteRooms: [HMRoom] {
        homes.flatMap(\\.rooms).filter(isFavorite)
    }

    var roomCount: Int {
        homes.reduce(0) { $0 + $1.rooms.count }
    }

    var lightAccessories: [HMAccessory] {
        homes.flatMap(\.accessories).filter(isLight)
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

    private func write(_ value: NSNumber, to characteristic: HMCharacteristic?, accessory: HMAccessory, feature: String) {
        guard accessory.isReachable, let characteristic else {
            errorMessage = "\(accessory.name) saknar stöd för \(feature) eller kan inte nås."
            revision += 1
            return
        }
        characteristic.writeValue(value) { [weak self] error in
            Task { @MainActor in
                if let error {
                    self?.errorMessage = "Kunde inte ändra \(feature) på \(accessory.name): \(error.localizedDescription)"
                } else {
                    self?.errorMessage = nil
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
        let states = lightAccessories.compactMap(powerState(for:))
        guard !lightAccessories.isEmpty, states.count == lightAccessories.count else { return nil }
        return states.allSatisfy { $0 }
    }

    func setAllLights(_ isOn: Bool) {
        lightAccessories.forEach { setPower(isOn, for: $0) }
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
        pendingPowerAccessoryIDs.insert(accessory.uniqueIdentifier)
        revision += 1
        characteristic.writeValue(isOn) { [weak self] error in
            Task { @MainActor in
                self?.pendingPowerAccessoryIDs.remove(accessory.uniqueIdentifier)
                if let error {
                    self?.errorMessage = "Kunde inte styra \(accessory.name): \(error.localizedDescription)"
                } else {
                    self?.errorMessage = nil
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
        characteristic.writeValue(NSNumber(value: Int(value.rounded()))) { [weak self] error in
            Task { @MainActor in
                if let error {
                    self?.errorMessage = "Kunde inte dimra \(accessory.name): \(error.localizedDescription)"
                } else {
                    self?.errorMessage = nil
                }
                self?.revision += 1
            }
        }
    }

    private func characteristic(for accessory: HMAccessory, type: String) -> HMCharacteristic? {
        accessory.services
            .flatMap(\.characteristics)
            .first { $0.characteristicType == type }
    }
}
