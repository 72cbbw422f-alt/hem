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

    func accessory(_ accessory: HMAccessory, didUpdateValueFor characteristic: HMCharacteristic) {
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

    func setPower(_ isOn: Bool, for accessory: HMAccessory) {
        guard accessory.isReachable, let characteristic = powerCharacteristic(for: accessory) else {
            errorMessage = "\(accessory.name) kan inte nås just nu."
            revision += 1
            return
        }
        characteristic.writeValue(isOn) { [weak self] error in
            Task { @MainActor in
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
