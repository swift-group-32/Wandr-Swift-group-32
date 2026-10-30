import Foundation

// RULES for the sign up and log in fields.

enum AuthRules {

    static let maxNameLength = 40
    static let maxEmailLength = 100
    static let minPasswordLength = 8
    static let maxPasswordLength = 64
    static let codeLength = 8



    static func nameError(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.count < 2 {
            return "Your name must have at least 2 characters."
        }
        return nil
    }

    static func emailError(_ email: String) -> String? {
        let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        if email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) == nil {
            return "Enter a valid email, like name@example.com."
        }
        return nil
    }

    static func passwordError(_ password: String) -> String? {
        if password.count < minPasswordLength {
            return "Your password must have at least \(minPasswordLength) characters."
        }
        if password.rangeOfCharacter(from: .letters) == nil
            || password.rangeOfCharacter(from: .decimalDigits) == nil {
            return "Your password must have at least one letter and one number."
        }
        return nil
    }
}
