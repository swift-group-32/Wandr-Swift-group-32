import Foundation

struct ExploreEvent: Identifiable {

    let id: String

    let title: String

    let category: String

    let location: String

    let time: String

    let participants: String

    let xp: String

    let icon: String

    let startsAt: Date

    let endsAt: Date?

    let description: String

    let coverImageURL: String?

    let capacity: Int?

    let attendeeCount: Int
}
