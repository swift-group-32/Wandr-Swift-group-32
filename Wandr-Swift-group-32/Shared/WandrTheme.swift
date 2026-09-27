import SwiftUI

extension Color {
    static let wandrGreen = Color(red: 22/255, green: 56/255, blue: 32/255)    // #163820 primary
    static let wandrSage  = Color(red: 90/255, green: 123/255, blue: 98/255)   // #5A7B62 secundary
    static let wandrSand  = Color(red: 191/255, green: 167/255, blue: 138/255) // #BFA78A thirdary
    static let wandrCream = Color(red: 252/255, green: 250/255, blue: 246/255) // #FCFAF6 neutral
}

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(16)
    }
}
