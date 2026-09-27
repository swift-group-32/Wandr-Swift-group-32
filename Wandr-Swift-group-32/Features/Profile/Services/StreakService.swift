import Foundation

class StreakService {

    let baseURL = "http://localhost:3000"
    let useMockData = true

    func fetchStreak(userId: String) async throws -> StreakDTO {
        if useMockData {
            return StreakDTO.mock
        }

        let url = URL(string: "\(baseURL)/users/\(userId)/streak")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(StreakDTO.self, from: data)
    }
}
