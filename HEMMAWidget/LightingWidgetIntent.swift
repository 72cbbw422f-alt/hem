import AppIntents
import Foundation
import HomeKit
import WidgetKit

enum LightingStatusStore {
    static let suiteName = "group.se.hemma.shared"
    static func key(kind: String, name: String) -> String { "\(kind):\(name)" }

    static func save(_ value: Bool, kind: String, name: String) {
        UserDefaults(suiteName: suiteName)?.set(value, forKey: key(kind: kind, name: name))
    }

    static func value(kind: String, name: String) -> Bool? {
        UserDefaults(suiteName: suiteName)?.object(forKey: key(kind: kind, name: name)) as? Bool
    }
}

struct ToggleWidgetLightIntent: AppIntent {
    static var title: LocalizedStringResource = "Växla belysning"
    static var description = IntentDescription("Tänder eller släcker en lampa eller all belysning i ett rum.")
    static var openAppWhenRun = false

    @Parameter(title: "Typ") var kind: String
    @Parameter(title: "Namn") var name: String

    init() {
        kind = "device"
        name = ""
    }

    init(kind: String, name: String) {
        self.kind = kind
        self.name = name
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try await WidgetHomeKitController.shared.toggle(kind: kind, name: name)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

@MainActor
private final class WidgetHomeKitController: NSObject, HMHomeManagerDelegate {
    static let shared = WidgetHomeKitController()
    private let manager = HMHomeManager()
    private var isReady = false
    private var readyWaiters: [CheckedContinuation<Void, Error>] = []

    private override init() {
        super.init()
        manager.delegate = self
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        isReady = true
        let waiters = readyWaiters
        readyWaiters.removeAll()
        waiters.forEach { $0.resume() }
    }

    func toggle(kind: String, name: String) async throws {
        try await waitUntilReady()
        guard manager.authorizationStatus.contains(.authorized) else {
            throw WidgetLightingError.notAuthorized
        }

        let homes = manager.homes
        // Refresh the shared snapshot so every tile has a current status.
        for accessory in homes.flatMap(\.accessories) {
            if let state = powerCharacteristic(for: accessory)?.value as? Bool {
                LightingStatusStore.save(state, kind: "device", name: accessory.name)
            }
        }

        for room in homes.flatMap(\.rooms) {
            let lights = room.accessories.filter {
                $0.services.contains { $0.serviceType == HMServiceTypeLightbulb }
            }
            if !lights.isEmpty {
                let isOn = lights.allSatisfy { powerCharacteristic(for: $0)?.value as? Bool == true }
                LightingStatusStore.save(isOn, kind: "room", name: room.name)
            }
        }

        if kind == "device" {
            guard let accessory = homes.flatMap(\.accessories).first(where: {
                $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame &&
                $0.services.contains { $0.serviceType == HMServiceTypeLightbulb }
            }) else { throw WidgetLightingError.notFound(name) }
            guard accessory.isReachable, let current = powerCharacteristic(for: accessory)?.value as? Bool else {
                throw WidgetLightingError.unavailable(accessory.name)
            }
            let targetState = !current
            try await write(targetState, to: accessory)
            LightingStatusStore.save(targetState, kind: "device", name: accessory.name)
            return
        }

        guard kind == "room",
              let room = homes.flatMap(\.rooms).first(where: {
                  $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
              }) else { throw WidgetLightingError.notFound(name) }

        let lights = room.accessories.filter {
            $0.services.contains { $0.serviceType == HMServiceTypeLightbulb }
        }
        guard !lights.isEmpty else { throw WidgetLightingError.noLights(name) }
        let turnOn = !lights.allSatisfy { powerCharacteristic(for: $0)?.value as? Bool == true }
        for light in lights where light.isReachable {
            try await write(turnOn, to: light)
            LightingStatusStore.save(turnOn, kind: "device", name: light.name)
        }
        LightingStatusStore.save(turnOn, kind: "room", name: room.name)
    }

    private func waitUntilReady() async throws {
        if isReady { return }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            readyWaiters.append(continuation)
        }
    }

    private func toggle(_ accessory: HMAccessory) async throws {
        guard accessory.isReachable, let characteristic = powerCharacteristic(for: accessory),
              let current = characteristic.value as? Bool else {
            throw WidgetLightingError.unavailable(accessory.name)
        }
        try await write(!current, to: accessory)
    }

    private func powerCharacteristic(for accessory: HMAccessory) -> HMCharacteristic? {
        accessory.services
            .filter { $0.serviceType == HMServiceTypeLightbulb }
            .flatMap(\.characteristics)
            .first { $0.characteristicType == HMCharacteristicTypePowerState }
    }

    private func write(_ value: Bool, to accessory: HMAccessory) async throws {
        guard accessory.isReachable, let characteristic = powerCharacteristic(for: accessory) else {
            throw WidgetLightingError.unavailable(accessory.name)
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            characteristic.writeValue(value) { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }
}

private enum WidgetLightingError: LocalizedError {
    case notAuthorized
    case notFound(String)
    case noLights(String)
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "HEMMA saknar behörighet till Apple Hem. Öppna appen och kontrollera HomeKit-åtkomsten."
        case .notFound(let name): return "Hittar ingen lampa eller inget rum med namnet \(name)."
        case .noLights(let name): return "Det finns inga lampor i rummet \(name)."
        case .unavailable(let name): return "\(name) kan inte nås eller saknar strömbrytare."
        }
    }
}
