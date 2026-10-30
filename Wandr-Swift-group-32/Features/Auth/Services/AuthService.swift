import Foundation
import Supabase



class AuthService {

    func hasSession() async -> Bool {
        do {
            _ = try await supabase.auth.session
            return true
        } catch {
            return false
        }
    }

    func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(email: email, password: password)
    }

    func signUp(name: String, email: String, password: String) async throws {
        try await supabase.auth.signUp(
            email: email,
            password: password,
            data: ["name": .string(name), "full_name": .string(name)]
        )
    }

    func verifyCode(email: String, code: String) async throws {
        try await supabase.auth.verifyOTP(email: email, token: code, type: .signup)
    }

    func resendCode(email: String) async throws {
        try await supabase.auth.resend(email: email, type: .signup)
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
    }
}

