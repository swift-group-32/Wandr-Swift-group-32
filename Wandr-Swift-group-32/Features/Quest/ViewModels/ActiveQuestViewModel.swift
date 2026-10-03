import Foundation
import Combine
import CoreLocation

@MainActor
class ActiveQuestViewModel: ObservableObject {

    @Published var activeQuest: ActiveQuestDTO? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    @Published var isWorking = false
    @Published var actionError: String? = nil
    @Published var reviewContext: ReviewContext? = nil
    @Published var startableQuests: [StartableQuestDTO] = []

    private let service: any ActiveQuestServing

    init(service: (any ActiveQuestServing)? = nil) {
        self.service = service ?? ActiveQuestService()
    }

    func loadActiveQuest(showLoading: Bool = true) async {
        if showLoading { isLoading = true }
        errorMessage = nil

        do {
            activeQuest = try await service.fetchActiveQuest()
            startableQuests = activeQuest == nil ? try await service.fetchStartableQuests() : []
        } catch {
            print("Active quest error:", error)
            errorMessage = "Could not load your quest. Check your connection."
        }

        isLoading = false
    }

    func startQuest(_ quest: StartableQuestDTO) async {
        guard !isWorking else { return }
        isWorking = true
        actionError = nil
        defer { isWorking = false }
        do {
            try await service.startQuest(questId: quest.id)
            await loadActiveQuest(showLoading: false)
        } catch {
            actionError = "Could not start this quest. Please try again."
        }
    }

    func checkObjective(_ objective: QuestObjective) async {
        guard !isChecked(objective), !objective.requiresPhoto else { return }

        isWorking = true
        do {
            try await complete(objective, photoPath: nil)
        } catch {
            print("Check objective error:", error)
            actionError = "Could not check this step. Try again."
        }
        isWorking = false
    }

    func submitPhoto(for objective: QuestObjective, imageData: Data) async {
        guard let activeQuest = activeQuest, !isChecked(objective) else { return }

        isWorking = true
        do {
            let path = try await service.uploadProofPhoto(
                questId: activeQuest.questId,
                objectiveId: objective.id,
                imageData: imageData
            )
            try await complete(objective, photoPath: path)
        } catch {
            print("Submit photo error:", error)
            actionError = "Could not upload the photo. Try again."
        }
        isWorking = false
    }

    private func complete(_ objective: QuestObjective, photoPath: String?) async throws {
        guard let activeQuest = activeQuest else { return }

        let result = try await service.completeObjective(
            questId: activeQuest.questId,
            objectiveId: objective.id,
            photoPath: photoPath
        )

        if result.questCompleted {
            reviewContext = ReviewContext(
                questId: activeQuest.questId,
                title: activeQuest.quest.title,
                placeName: activeQuest.quest.place.name,
                address: activeQuest.quest.place.address,
                xpEarned: result.xpEarned
            )
        }

        await loadActiveQuest(showLoading: false)
    }

    func giveUp() async {
        guard let activeQuest = activeQuest else { return }

        isWorking = true
        do {
            try await service.abandonQuest(questId: activeQuest.questId)
            await loadActiveQuest(showLoading: false)
        } catch {
            print("Give up error:", error)
            actionError = "Could not give up the quest. Try again."
        }
        isWorking = false
    }

    var navigationURL: URL? {
        guard let place = activeQuest?.quest.place else { return nil }
        return URL(string: "http://maps.apple.com/?daddr=\(place.latitude),\(place.longitude)")
    }

        let arrivalRadius: Double = 100

        func isAtDestination(_ userLocation: CLLocation?) -> Bool {
            guard let userLocation = userLocation,
                  let place = activeQuest?.quest.place else { return false }

            let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
            return userLocation.distance(from: placeLocation) <= arrivalRadius
        }

        var nextObjective: QuestObjective? {
            objectives.first { !isChecked($0) }
        }

    var objectives: [QuestObjective] {
        let list = activeQuest?.quest.objectives ?? []
        return list.sorted { $0.orderIndex < $1.orderIndex }
    }

    func isChecked(_ objective: QuestObjective) -> Bool {
        let checked = activeQuest?.checked ?? []
        return checked.contains { $0.objectiveId == objective.id }
    }

    var checkedCount: Int {
        objectives.filter { isChecked($0) }.count
    }

    var totalCount: Int {
        objectives.count
    }

    var progress: Double {
        if totalCount == 0 { return 0 }
        return Double(checkedCount) / Double(totalCount)
    }
}
