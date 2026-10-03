import Foundation
import Supabase

private struct SupabaseQuest: Decodable {

    let id: UUID
    let title: String
    let description: String?
    let estimated_duration: Int?
    let places: SupabaseQuestPlace?
}

private struct SupabaseQuestCompletion: Decodable {

    let quest_id: UUID
    let status: String
}

private struct SupabaseExploreEvent: Decodable {

    let id: UUID
    let title: String
    let description: String?
    let cover_image_url: String?
    let starts_at: String
    let ends_at: String?
    let capacity: Int?

    let places: SupabaseEventPlace?

    let event_attendees:
        [SupabaseAttendeeCount]?

    var attendeesCount: Int {

        event_attendees?.reduce(0) {
            $0 + ($1.count ?? 0)
        } ?? 0
    }
}

private struct SupabaseEventPlace: Decodable {

    let name: String?
    let category: String?
}

private struct SupabaseAttendeeCount: Decodable {

    let count: Int?
}

private struct SupabaseMysteryQuest: Decodable {

    let id: UUID
    let title: String
    let description: String?
    let difficulty_level: Int?
    let estimated_duration: Int?
    let points_reward: Int
    let places: SupabaseQuestPlace?
}

private struct SupabaseQuestPlace: Decodable {

    let name: String?
    let category: String?
    let average_rating: Double?
}

private struct SupabaseNearbyQuest: Decodable {

    let id: UUID
    let title: String
    let estimated_duration: Int?
    let place_name: String
    let distance_km: Double
}

class SupabaseQuestRepository: QuestRepository {

    private let supabase =
        SupabaseManager.shared.client

    // MARK: - BQ5

    func getPersonalizedQuests(
        userId: String
    ) async throws -> [Quest] {

        // Get all quests with their place information
        let quests: [SupabaseQuest] =
            try await supabase
                .from("quests")
                .select(
                    """
                    id,
                    title,
                    description,
                    estimated_duration,
                    places(
                        category,
                        average_rating
                    )
                    """
                )
                .execute()
                .value

        // Get the quests completed by this user
        let completions: [SupabaseQuestCompletion] =
            try await supabase
                .from("quest_completions")
                .select(
                    """
                    quest_id,
                    status
                    """
                )
                .eq(
                    "user_id",
                    value: userId
                )
                .execute()
                .value

        let completedQuestIds = Set(
            completions
                .filter {
                    $0.status.lowercased() == "completed"
                }
                .map {
                    $0.quest_id
                }
        )

        return quests.map { quest in

            let category =
                categoryFromPlace(
                    quest.places?.category
                        ?? "other"
                )

            let rating =
                quest.places?.average_rating
                    ?? 0

            let isCompleted =
                completedQuestIds.contains(
                    quest.id
                )

            return Quest(

                id:
                    quest.id.uuidString,

                title:
                    quest.title,

                category:
                    category,

                description:
                    quest.description ?? "",

                duration:
                    quest.estimated_duration ?? 0,

                rating:
                    rating,

                isCompleted:
                    isCompleted,

                isSaved:
                    false
            )
        }
    }

    // MARK: - Upcoming Events

    func getUpcomingEvents()
        async throws -> [ExploreEvent] {

        let now =
            ISO8601DateFormatter()
                .string(from: Date())

        let events:
            [SupabaseExploreEvent] =
            try await supabase
                .from("events")
                .select(
                    """
                    id,
                    title,
                    description,
                    cover_image_url,
                    starts_at,
                    ends_at,
                    capacity,
                    places(name, category),
                    event_attendees(count)
                    """
                )
                .gte(
                    "starts_at",
                    value: now
                )
                .order(
                    "starts_at",
                    ascending: true
                )
                .execute()
                .value

        return events.map {
            mapEvent($0)
        }
    }

    // MARK: - All Events

    func getAllEvents()
        async throws -> [ExploreEvent] {

        let events:
            [SupabaseExploreEvent] =
            try await supabase
                .from("events")
                .select(
                    """
                    id,
                    title,
                    description,
                    cover_image_url,
                    starts_at,
                    ends_at,
                    capacity,
                    places(name, category),
                    event_attendees(count)
                    """
                )
                .order(
                    "starts_at",
                    ascending: true
                )
                .execute()
                .value

        return events.map {
            mapEvent($0)
        }
    }

    // MARK: - Event Mapping

    private func mapEvent(
        _ event: SupabaseExploreEvent
    ) -> ExploreEvent {

        let startsAt =
            parseEventDate(
                event.starts_at
            ) ?? Date()

        let endsAt =
            event.ends_at.flatMap {
                parseEventDate($0)
            }

        let category =
            categoryFromPlace(
                event.places?.category
                    ?? "other"
            )

        return ExploreEvent(

            id:
                event.id.uuidString,

            title:
                event.title,

            category:
                category,

            location:
                event.places?.name
                    ?? "Bogotá",

            time:
                formatEventDate(
                    event.starts_at
                ),

            participants:
                "\(event.attendeesCount) going",

            xp:
                "+50 XP",

            icon:
                iconForCategory(
                    category
                ),

            startsAt:
                startsAt,

            endsAt:
                endsAt,

            description:
                event.description
                    ?? "No description available.",

            coverImageURL:
                event.cover_image_url,

            capacity:
                event.capacity,

            attendeeCount:
                event.attendeesCount
        )
    }

    // MARK: - Mystery Quest

    func getMysteryQuest(
        energyLevel: String
    ) async throws -> Quest {

        let quests:
            [SupabaseMysteryQuest] =
            try await supabase
                .from("quests")
                .select(
                    """
                    id,
                    title,
                    description,
                    difficulty_level,
                    estimated_duration,
                    points_reward,
                    places(name, category)
                    """
                )
                .execute()
                .value

        let filteredQuests:
            [SupabaseMysteryQuest]

        switch energyLevel {

        case "Low":

            filteredQuests =
                quests.filter {
                    ($0.difficulty_level ?? 1)
                    <= 2
                }

        case "High":

            filteredQuests =
                quests.filter {
                    ($0.difficulty_level ?? 1)
                    >= 4
                }

        default:

            filteredQuests =
                quests.filter {

                    let difficulty =
                        $0.difficulty_level
                        ?? 3

                    return difficulty == 3
                }
        }

        let availableQuests =
            filteredQuests.isEmpty
            ? quests
            : filteredQuests

        guard
            let selectedQuest =
                availableQuests.randomElement()
        else {

            throw NSError(
                domain:
                    "SupabaseQuestRepository",

                code:
                    1,

                userInfo: [
                    NSLocalizedDescriptionKey:
                        "No quests available."
                ]
            )
        }

        let category =
            categoryFromPlace(
                selectedQuest.places?.category
                    ?? "other"
            )

        return Quest(

            id:
                selectedQuest.id.uuidString,

            title:
                selectedQuest.title,

            category:
                category,

            description:
                selectedQuest.description
                    ?? "",

            duration:
                selectedQuest
                    .estimated_duration
                    ?? 0,

            rating:
                0,

            isCompleted:
                false,

            isSaved:
                false
        )
    }

    // MARK: - Nearby Quests

    func getNearbyQuests(
        latitude: Double,
        longitude: Double,
        radius: Double = 5
    ) async throws -> [NearbyQuest] {

        let quests:
            [SupabaseNearbyQuest] =
            try await supabase
                .rpc(
                    "nearby_quests",
                    params: [
                        "p_lat": latitude,
                        "p_lng": longitude,
                        "p_radius_km": radius
                    ]
                )
                .execute()
                .value

        return quests.map { quest in

            NearbyQuest(

                id:
                    quest.id.uuidString,

                title:
                    quest.title,

                duration:
                    quest.estimated_duration
                    ?? 0,

                location:
                    quest.place_name,

                distance:
                    quest.distance_km
            )
        }
    }

    // MARK: - Date Helpers

    private func parseEventDate(
        _ value: String
    ) -> Date? {

        let formatter =
            ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        if let date =
            formatter.date(from: value) {

            return date
        }

        formatter.formatOptions = [
            .withInternetDateTime
        ]

        return formatter.date(
            from: value
        )
    }

    private func formatEventDate(
        _ value: String
    ) -> String {

        guard
            let date =
                parseEventDate(value)
        else {

            return "Upcoming"
        }

        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(identifier: "en_US")

        formatter.dateFormat =
            "EEE · MMM d · h:mm a"

        return formatter.string(
            from: date
        )
    }

    // MARK: - Category Helpers

    private func categoryFromPlace(
        _ category: String
    ) -> String {

        switch category.lowercased() {

        case "park", "outdoors":

            return "Outdoor"

        case "restaurant":

            return "Food"

        case "museum", "culture":

            return "Culture"

        case "bar":

            return "Music"

        case "event":

            return "Music"

        default:

            return "Other"
        }
    }

    private func iconForCategory(
        _ category: String
    ) -> String {

        switch category.lowercased() {

        case "outdoor":

            return "figure.hiking"

        case "food":

            return "fork.knife"

        case "culture":

            return "paintpalette"

        case "music":

            return "music.note"

        default:

            return "sparkles"
        }
    }
}
