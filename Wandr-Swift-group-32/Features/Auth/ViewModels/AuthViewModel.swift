import Foundation
import Combine

// The 3 screens of the auth flow
enum AuthScreen {
    case login
    case signUp
    case verifyCode
}


class AuthViewModel: ObservableObject {



    @Published var isLoggedIn = false
    @Published var isCheckingSession = true

    // Which auth screen is visible
    @Published var screen: AuthScreen = .login



    @Published var name = "" {
        didSet {
            if name.count > AuthRules.maxNameLength {
                name = String(name.prefix(AuthRules.maxNameLength))
            }
        }
    }

    @Published var email = "" {
        didSet {
            if email.count > AuthRules.maxEmailLength {
                email = String(email.prefix(AuthRules.maxEmailLength))
            }
        }
    }

    @Published var password = "" {
        didSet {
            if password.count > AuthRules.maxPasswordLength {
                password = String(password.prefix(AuthRules.maxPasswordLength))
            }
        }
    }

    @Published var confirmPassword = "" {
        didSet {
            if confirmPassword.count > AuthRules.maxPasswordLength {
                confirmPassword = String(confirmPassword.prefix(AuthRules.maxPasswordLength))
            }
        }
    }

    // Only numbers, and at most 6
    @Published var code = "" {
        didSet {
            let limited = String(code.filter { $0.isNumber }.prefix(AuthRules.codeLength))
            if limited != code {
                code = limited
            }
        }
    }



    @Published var isWorking = false
    @Published var errorMessage: String? = nil
    @Published var infoMessage: String? = nil

    private let service = AuthService()

    // The email without spaces and in lowercase
    var cleanEmail: String {
        email.trimmingCharacters(in: .whitespaces).lowercased()
    }


    func checkSession() async {
        isLoggedIn = await service.hasSession()
        isCheckingSession = false
    }

    func logIn() async {
        if let error = AuthRules.emailError(cleanEmail) {
            errorMessage = error
            return
        }
        if password.isEmpty {
            errorMessage = "Enter your password."
            return
        }

        isWorking = true
        errorMessage = nil
        do {
            try await service.signIn(email: cleanEmail, password: password)
            finishLogin()
        } catch {
            if isEmailNotConfirmed(error) {
                try? await service.resendCode(email: cleanEmail)
                go(to: .verifyCode)
                infoMessage = "Confirm your email first. We sent a new code to \(cleanEmail)."
            } else {
                errorMessage = friendlyMessage(for: error)
            }
        }
        isWorking = false
    }

    func signUp() async {
        if let error = AuthRules.nameError(name)
            ?? AuthRules.emailError(cleanEmail)
            ?? AuthRules.passwordError(password) {
            errorMessage = error
            return
        }
        if password != confirmPassword {
            errorMessage = "The passwords do not match."
            return
        }

        isWorking = true
        errorMessage = nil
        do {
            try await service.signUp(
                name: name.trimmingCharacters(in: .whitespaces),
                email: cleanEmail,
                password: password
            )
            go(to: .verifyCode)
            infoMessage = "We sent a 8 digit code to \(cleanEmail)."
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
        isWorking = false
    }

    func verifyCode() async {
        if code.count != AuthRules.codeLength {
            errorMessage = "Enter the 8 digit code from the email."
            return
        }

        isWorking = true
        errorMessage = nil
        do {
            try await service.verifyCode(email: cleanEmail, code: code)
            finishLogin()
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
        isWorking = false
    }

    func resendCode() async {
        isWorking = true
        errorMessage = nil
        do {
            try await service.resendCode(email: cleanEmail)
            infoMessage = "We sent a new code to \(cleanEmail)."
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
        isWorking = false
    }

    func logOut() async {
        do {
            try await service.signOut()
        } catch {
            print("Log out error:", error)
        }
        name = ""
        password = ""
        confirmPassword = ""
        code = ""
        isLoggedIn = false
        go(to: .login)
    }

    func go(to newScreen: AuthScreen) {
        screen = newScreen
        errorMessage = nil
        infoMessage = nil
        code = ""
    }


    private func finishLogin() {
        password = ""
        confirmPassword = ""
        code = ""
        isLoggedIn = true
    }

    private func isEmailNotConfirmed(_ error: Error) -> Bool {
        String(describing: error).lowercased().contains("not confirmed")
    }

    private func friendlyMessage(for error: Error) -> String {
        print("Auth error:", error)
        let text = String(describing: error).lowercased()

        if text.contains("invalid login credentials") {
            return "Wrong email or password."
        }
        if text.contains("already registered") {
            return "This email already has an account. Log in instead."
        }
        if text.contains("expired") || (text.contains("invalid") && text.contains("token")) {
            return "The code is wrong or expired. Try again or ask for a new one."
        }
        if text.contains("rate limit") || text.contains("security purposes") {
            return "Too many attempts. Wait a minute and try again."
        }
        if text.contains("offline") || text.contains("internet") || text.contains("network") {
            return "No internet connection. Check it and try again."
        }
        return "Something went wrong. Try again."
    }
}
