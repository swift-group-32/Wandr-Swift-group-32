import Foundation

struct Quest: Identifiable {
    let id: String
    let title: String
    let category: String
    let description: String
    let duration: Int
    let rating: Double
    let isCompleted: Bool
    var isSaved: Bool
}
