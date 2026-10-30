import SwiftUI

struct VerifyCodeView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                Image("WandrBearWave")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
                    .padding(.top, 32)

                VStack(spacing: 6) {
                    Text("Check your email")
                        .font(.title).bold()
                        .foregroundColor(.wandrGreen)
                    Text("Enter the \(AuthRules.codeLength)-digit code we sent to \(auth.cleanEmail)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }

                TextField("000000", text: $auth.code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .authFieldStyle()

                AuthMessages(error: auth.errorMessage, info: auth.infoMessage)

                AuthPrimaryButton(title: "Confirm", isWorking: auth.isWorking) {
                    Task { await auth.verifyCode() }
                }

                Button("Resend code") {
                    Task { await auth.resendCode() }
                }
                .font(.subheadline).bold()
                .foregroundColor(.wandrGreen)
                .disabled(auth.isWorking)

                Button("Use a different email") {
                    auth.go(to: .signUp)
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.wandrCream.ignoresSafeArea())
    }
}

#Preview {
    VerifyCodeView()
        .environmentObject(AuthViewModel())
}
