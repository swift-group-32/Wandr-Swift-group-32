import Foundation
internal import Combine

@MainActor
class ActiveQuestViewModel: ObservableObject {

    @Published var activeQuest: ActiveQuestDTO? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    @Published var isWorking = false
    @Published var actionError: String? = nil

    private let service = ActiveQuestService()

    func loadActiveQuest(showLoading: Bool = true) async {
        if showLoading { isLoading = true }
        errorMessage = nil

        do {
            activeQuest = try await service.fetchActiveQuest()
        } catch {
            print("Active quest error:", error)
            errorMessage = "Could not load your quest. Check your connection."
        }

        isLoading = false
    }

    func checkObjective(_ objective: QuestObjective) async {
        guard let activeQuest = activeQuest,
              !isChecked(objective),
              !objective.requiresPhoto else { return }

        isWorking = true
        do {
            try await service.completeObjective(
                questId: activeQuest.questId,
                objectiveId: objective.id
            )
            await loadActiveQuest(showLoading: false)
        } catch {
            print("Check objective error:", error)
            actionError = "Could not check this step. Try again."
        }
        isWorking = false
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
