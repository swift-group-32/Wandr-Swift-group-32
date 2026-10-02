import Foundation


class ActiveQuestService {

    // true  = mock data
    // false = calls Supabase
    let useMockData = true

    func fetchActiveQuest() async throws -> ActiveQuestDTO? {
        if useMockData {
            return ActiveQuestDTO.mock
        }

        return nil // TODO: phase 2, read from Supabase
    }
}
