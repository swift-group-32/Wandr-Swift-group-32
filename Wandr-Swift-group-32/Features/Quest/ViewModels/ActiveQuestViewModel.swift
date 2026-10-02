import Foundation
public import Combine


@MainActor
class ActiveQuestViewModel: ObservableObject {

    @Published var activeQuest: ActiveQuestDTO? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let service = ActiveQuestService()

    func loadActiveQuest() async {
        isLoading = true
        errorMessage = nil

        do {
            activeQuest = try await service.fetchActiveQuest()
        } catch {
            print("Active quest error:", error)
            errorMessage = "Could not load your quest. Check your connection."
        }

        isLoading = false
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
