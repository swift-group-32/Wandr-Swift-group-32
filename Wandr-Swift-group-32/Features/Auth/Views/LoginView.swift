import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image("WandrLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .padding(.top, 32)

                VStack(spacing: 4) {
                    Text("Welcome back")
                        .font(.title).bold()
                        .foregroundColor(.wandrGreen)
                    Text("Log in to keep exploring Bogotá")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                VStack(spacing: 12) {
                    TextField("Email", text: $auth.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .authFieldStyle()

                    PasswordField(placeholder: "Password", text: $auth.password)
                }

                AuthMessages(error: auth.errorMessage, info: auth.infoMessage)

                AuthPrimaryButton(title: "Log in", isWorking: auth.isWorking) {
                    Task { await auth.logIn() }
                }

                HStack(spacing: 4) {
                    Text("New to Wandr?")
                        .foregroundColor(.gray)
                    Button("Create an account") {
                        auth.go(to: .signUp)
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
    LoginView()
        .environmentObject(AuthViewModel())
}
