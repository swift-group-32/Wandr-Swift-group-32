import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://cugtwwqqxczwtkfkubrf.supabase.co")!,
    supabaseKey: "sb_publishable_YPjvNLSqznQitYTinqvabg_p8V5e8-i"
)

// TEMPORARY: log in with a seed test user until the login screen exists.
// Remove this function (and its calls) when authentication is integrated.
func signInTestUserIfNeeded() async throws {
    if supabase.auth.currentSession == nil {
        try await supabase.auth.signIn(
            email: "valentina.gomez@example.com",
            password: "password123"
        )
    }
}
