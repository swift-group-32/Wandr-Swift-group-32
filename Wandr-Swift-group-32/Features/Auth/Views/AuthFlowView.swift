import SwiftUI

struct AuthFlowView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        switch auth.screen {
        case .login:
            LoginView()
        case .signUp:
            SignUpView()
        case .verifyCode:
            VerifyCodeView()
        }
    }
}
