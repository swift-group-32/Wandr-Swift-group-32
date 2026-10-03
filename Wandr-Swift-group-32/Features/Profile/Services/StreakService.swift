import Foundation
import Supabase


class StreakService {

    // true  = mock data StreakDTO.mock
    // false = calls Supabase
    let useMockData = false

    func fetchStreak(userId: String) async throws -> StreakDTO {
        if useMockData {
            return StreakDTO.mock
        }

        //        if supabase.auth.currentSession == nil {
        //  try await supabase.auth.signIn(
        //      email: "valentina.gomez@example.com",
        //      password: "password123"
        //  )
        //}
        
        try await signInTestUserIfNeeded()

        
        let response = try await supabase
                   .rpc("get_streak_summary")
                   .execute()

               let decoder = JSONDecoder()
               decoder.keyDecodingStrategy = .convertFromSnakeCase
               return try decoder.decode(StreakDTO.self, from: response.data)
    }
}
