import Foundation
import Supabase

let supabase = SupabaseManager.shared.client

// TEMPORARY: log in with a seed test user until the login screen exists.
// Remove this function (and its calls) when authentication is integrated.
func requireSession() async throws {
    _ = try await supabase.auth.session
}
