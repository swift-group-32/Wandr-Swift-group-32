import Combine
import CoreLocation
import Foundation

enum MapLocationState: Equatable {
    case permissionRequired, locating, denied, unavailable
    case located(MapPoint, approximate: Bool)

    var point: MapPoint? {
        if case let .located(point, _) = self { return point }
        return nil
    }
}

@MainActor
protocol MapLocationProviding {
    var state: MapLocationState { get }
    var updates: AnyPublisher<MapLocationState, Never> { get }
    func start()
    func stop()
}

@MainActor
final class MapLocationService: NSObject, MapLocationProviding, CLLocationManagerDelegate {
    @Published private(set) var state: MapLocationState = .permissionRequired
    var updates: AnyPublisher<MapLocationState, Never> { $state.eraseToAnyPublisher() }
    private let manager = CLLocationManager()
    private var isActive = false
    private var lastFix: Date?
    private var timeout: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 50
    }

    func start() {
        isActive = true
        applyAuthorization(manager.authorizationStatus)
    }

    func stop() {
        isActive = false
        timeout?.cancel()
        manager.stopUpdatingLocation()
    }

    private func applyAuthorization(_ status: CLAuthorizationStatus) {
        guard isActive else { return }
        switch status {
        case .notDetermined:
            state = .permissionRequired
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            timeout?.cancel()
            manager.stopUpdatingLocation()
            state = .denied
        case .authorizedAlways, .authorizedWhenInUse:
            if state.point == nil || lastFix.map({ Date().timeIntervalSince($0) > 60 }) != false { state = .locating }
            manager.startUpdatingLocation()
            timeout?.cancel()
            timeout = Task { [weak self] in
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled, let self, self.state == .locating else { return }
                self.state = .unavailable
            }
        @unknown default:
            state = .unavailable
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in self.applyAuthorization(self.manager.authorizationStatus) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0,
              abs(location.timestamp.timeIntervalSinceNow) < 60 else { return }
        let point = MapPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let approximate = manager.accuracyAuthorization == .reducedAccuracy
        Task { @MainActor in
            guard self.isActive,
                  self.manager.authorizationStatus == .authorizedWhenInUse || self.manager.authorizationStatus == .authorizedAlways else { return }
            self.timeout?.cancel()
            self.lastFix = location.timestamp
            self.state = .located(point, approximate: approximate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let denied = (error as? CLError)?.code == .denied
        Task { @MainActor in
            guard self.isActive else { return }
            self.timeout?.cancel()
            self.state = denied ? .denied : .unavailable
        }
    }
}
