import Foundation
import Supabase

class SupabaseManager {

    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(
                string: "https://cugtwwqqxczwtkfkubrf.supabase.co"
            )!,
            supabaseKey:
                "sb_publishable_YPjvNLSqznQitYTinqvabg_p8V5e8-i"
        )
    }

    // MARK: - Testing Login

    func signInForTesting() async throws {

        try await client.auth.signIn(
            email: "valentina.gomez@example.com",
            password: "password123"
        )

        print("LOGIN EXITOSO")
    }

    // MARK: - Current User Name

    func getCurrentUserName() async -> String {

        do {

            let user = try await client.auth.user()

            if let fullName =
                user.userMetadata["full_name"]?.stringValue,
               !fullName.isEmpty {

                return fullName
            }

            if let username =
                user.userMetadata["username"]?.stringValue,
               !username.isEmpty {

                return username
            }

            if let email = user.email {

                return email.components(
                    separatedBy: "@"
                )[0]
            }

        } catch {

            print(
                "Could not get current user:",
                error
            )
        }

        return "User"
    }
}
