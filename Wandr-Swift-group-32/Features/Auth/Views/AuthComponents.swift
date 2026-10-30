import SwiftUI


extension View {
    func authFieldStyle() -> some View {
        self
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.wandrSand.opacity(0.5), lineWidth: 1)
            )
    }
}

struct AuthPrimaryButton: View {
    let title: String
    let isWorking: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .bold()
                    .opacity(isWorking ? 0 : 1)
                if isWorking {
                    ProgressView().tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.wandrGreen)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(isWorking)
    }
}

struct AuthMessages: View {
    let error: String?
    let info: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let info = info {
                Label(info, systemImage: "envelope")
                    .foregroundColor(.wandrGreen)
            }
            if let error = error {
                Label(error, systemImage: "exclamationmark.circle")
                    .foregroundColor(.red)
            }
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PasswordField: View {
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType = .password

    @State private var isVisible = false

    var body: some View {
        HStack {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textContentType(contentType)

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
            }
        }
        .authFieldStyle()
    }
}
