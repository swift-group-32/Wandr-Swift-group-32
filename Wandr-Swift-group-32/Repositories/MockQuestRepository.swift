import Foundation

class MockQuestRepository: QuestRepository {

    func getPersonalizedQuests(userId: String) async throws -> [Quest] {

        return [
            Quest(
                id: "1",
                title: "Visit a Local Art Gallery",
                category: "Art",
                description: "Discover a new exhibition near you.",
                duration: 60,
                rating: 4.8,
                isCompleted: false,
                isSaved: true
            ),
            Quest(
                id: "2",
                title: "Try a New Coffee Shop",
                category: "Food",
                description: "Visit a coffee shop you have never tried.",
                duration: 45,
                rating: 4.6,
                isCompleted: false,
                isSaved: false
            ),
            Quest(
                id: "3",
                title: "Go for a Bike Ride",
                category: "Outdoor",
                description: "Explore a new route around the city.",
                duration: 90,
                rating: 4.7,
                isCompleted: true,
                isSaved: false
            ),
            Quest(
                id: "4",
                title: "Explore Street Art",
                category: "Art",
                description: "Discover interesting street art around the city.",
                duration: 40,
                rating: 4.9,
                isCompleted: false,
                isSaved: true
            ),
            Quest(
                id: "5",
                title: "Visit a Local Park",
                category: "Outdoor",
                description: "Take a relaxing walk in a nearby park.",
                duration: 30,
                rating: 4.5,
                isCompleted: false,
                isSaved: false
            )
        ]
    }
}
