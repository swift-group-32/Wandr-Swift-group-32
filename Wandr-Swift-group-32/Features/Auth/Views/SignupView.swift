import SwiftUI


struct SignUpView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Create your account")
                        .font(.title).bold()
                        .foregroundColor(.wandrGreen)
                    Text("Start your first quest in Bogotá")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 48)

                VStack(alignment: .leading, spacing: 12) {
                    TextField("Name", text: $auth.name)
                        .textContentType(.name)
                        .authFieldStyle()

                    Text("\(auth.name.count)/\(AuthRules.maxNameLength)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    TextField("Email", text: $auth.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .authFieldStyle()

                    PasswordField(placeholder: "Password", text: $auth.password, contentType: .newPassword)
                    
                    PasswordField(placeholder: "Confirm password", text: $auth.confirmPassword, contentType: .newPassword)

                    
                    Text("At least \(AuthRules.minPasswordLength) characters, with a letter and a number.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                AuthMessages(error: auth.errorMessage, info: auth.infoMessage)

                AuthPrimaryButton(title: "Create account", isWorking: auth.isWorking) {
                    Task { await auth.signUp() }
                }

                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundColor(.gray)
                    Button("Log in") {
                        auth.go(to: .login)
                    }
                    .bold()
                    .foregroundColor(.wandrGreen)
                }
                .font(.subheadline)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.wandrCream.ignoresSafeArea())
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
