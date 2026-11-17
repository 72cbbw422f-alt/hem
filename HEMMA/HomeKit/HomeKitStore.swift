import Combine
import Foundation
import HomeKit

@MainActor
final class HomeKitStore: NSObject, ObservableObject, HMHomeManagerDelegate {
    @Published private(set) var homes: [HMHome] = []
    @Published private(set) var isAuthorized = false
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?

    private let manager = HMHomeManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        homes = manager.homes
        isAuthorized = true
        isLoading = false
        errorMessage = nil
    }

    func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        homes = manager.homes
    }

    func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
        homes = manager.homes
    }

    var roomCount: Int {
        homes.reduce(0) { $0 + $1.rooms.count }
    }

    var lightAccessories: [HMAccessory] {
        homes.flatMap(\.accessories).filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeLightbulb }
        }
    }

    var homeName: String? {
        homes.first?.name
    }
}
