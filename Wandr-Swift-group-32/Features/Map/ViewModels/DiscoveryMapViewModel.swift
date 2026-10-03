import Combine
import Foundation

@MainActor
final class DiscoveryMapViewModel: ObservableObject {
    static let radiusOptions = [1.0, 3.0, 5.0, 10.0]
    let activityDays = 30
    @Published private(set) var radiusKm = 5.0
    @Published private(set) var locationState: MapLocationState
    @Published private(set) var quests: [MapQuest] = []
    @Published private(set) var activity: NeighborhoodActivityReport?
    @Published private(set) var isLoadingNearby = false
    @Published private(set) var isLoadingActivity = false
    @Published private(set) var nearbyError: String?
    @Published private(set) var activityError: String?

    private let facade: any MapDataProviding
    private let location: any MapLocationProviding
    private var subscription: AnyCancellable?
    private var nearbyTask: Task<Void, Never>?
    private var activityTask: Task<Void, Never>?
    private var nearbyGeneration = 0
    private var activityGeneration = 0
    private var isActive = false

    init(facade: (any MapDataProviding)? = nil, location: (any MapLocationProviding)? = nil) {
        self.facade = facade ?? MapDataFacade()
        self.location = location ?? MapLocationService()
        locationState = self.location.state
        subscription = self.location.updates.removeDuplicates().sink { [weak self] state in
            guard let self else { return }
            let previousCenter = self.center
            self.locationState = state
            if self.isActive && previousCenter != self.center { self.reloadNearby() }
        }
    }

    var center: MapPoint { locationState.point ?? .bogota }
    var showsUserLocation: Bool { locationState.point != nil }
    var activeNeighborhoods: [NeighborhoodActivity] {
        activity?.neighborhoods.filter { $0.completedQuests > 0 } ?? []
    }
    var leadingNeighborhoods: [NeighborhoodActivity] {
        guard let highest = activeNeighborhoods.first?.completedQuests else { return [] }
        return activeNeighborhoods.filter { $0.completedQuests == highest }
    }

    var locationNotice: String? {
        switch locationState {
        case .permissionRequired: "Allow location access to find quests near you. Showing central Bogotá."
        case .locating: "Finding your location. Showing central Bogotá until GPS is available."
        case .denied: "Location access is off. Distances are from central Bogotá."
        case .unavailable: "Location unavailable. Distances are from central Bogotá."
        case .located(_, approximate: true): "Using your approximate location. Distances are estimates."
        case .located(_, approximate: false): nil
        }
    }

    func start() {
        guard !isActive else { return }
        isActive = true
        location.start()
        reloadNearby()
        reloadActivity()
    }

    func stop() {
        isActive = false
        location.stop()
        nearbyTask?.cancel()
        activityTask?.cancel()
        nearbyGeneration += 1
        activityGeneration += 1
        isLoadingNearby = false
        isLoadingActivity = false
    }

    func setRadius(_ radius: Double) {
        guard Self.radiusOptions.contains(radius), radius != radiusKm else { return }
        radiusKm = radius
        reloadNearby()
    }

    func reloadNearby() {
        nearbyTask?.cancel()
        nearbyTask = Task { [weak self] in await self?.loadNearby() }
    }

    func reloadActivity() {
        activityTask?.cancel()
        activityTask = Task { [weak self] in await self?.loadActivity() }
    }

    func refresh() async {
        async let nearby: Void = loadNearby()
        async let activity: Void = loadActivity()
        _ = await (nearby, activity)
    }

    // Generation checks prevent older coordinates/radii or canceled screen tasks
    // from replacing the current result, even if a transport ignores cancellation.
    func loadNearby() async {
        nearbyGeneration += 1
        let generation = nearbyGeneration
        let point = center
        let radius = radiusKm
        quests = []
        nearbyError = nil
        isLoadingNearby = true
        do {
            let result = try await facade.nearbyQuests(point: point, radiusKm: radius)
            guard !Task.isCancelled, generation == nearbyGeneration else { return }
            quests = result
        } catch {
            guard !Task.isCancelled, generation == nearbyGeneration else { return }
            nearbyError = "Could not load nearby quests. Check your connection and retry."
        }
        if generation == nearbyGeneration { isLoadingNearby = false }
    }

    func loadActivity() async {
        activityGeneration += 1
        let generation = activityGeneration
        activity = nil
        activityError = nil
        isLoadingActivity = true
        do {
            let result = try await facade.neighborhoodActivity(days: activityDays)
            guard !Task.isCancelled, generation == activityGeneration else { return }
            activity = result
        } catch {
            guard !Task.isCancelled, generation == activityGeneration else { return }
            activityError = "Neighborhood activity is unavailable. Please retry."
        }
        if generation == activityGeneration { isLoadingActivity = false }
    }
}
