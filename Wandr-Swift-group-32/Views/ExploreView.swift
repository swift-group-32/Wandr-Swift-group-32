import SwiftUI

struct ExploreView: View {

    @Binding var selectedTab: AppTab
    @Binding var savedQuestIds: Set<String>
    @Binding var savedEventIds: Set<String>
    @Binding var selectedCategory: String

    @State private var selectedDateFilter = "This Week"

    @State private var events: [ExploreEvent] = []
    @State private var quests: [Quest] = []

    @State private var isLoading = true
    @State private var questsLoading = true

    @State private var errorMessage: String?
    @State private var questsErrorMessage: String?

    @State private var selectedQuest: Quest?
    @State private var selectedEvent: ExploreEvent?

    let categories = [
        "All",
        "Outdoor",
        "Food",
        "Culture",
        "Music",
        "Games"
    ]

    // MARK: - Filtered Events

    private var filteredEvents: [ExploreEvent] {

        var resultado = events

        if selectedDateFilter == "This Week" {

            let calendar = Calendar.current
            let today = Date()

            let startOfWeek =
                calendar.date(
                    from:
                        calendar.dateComponents(
                            [
                                .yearForWeekOfYear,
                                .weekOfYear
                            ],
                            from: today
                        )
                ) ?? today

            let endOfWeek =
                calendar.date(
                    byAdding: .day,
                    value: 7,
                    to: startOfWeek
                ) ?? today

            resultado = resultado.filter { event in

                event.startsAt >= startOfWeek &&
                event.startsAt < endOfWeek
            }
        }

        if selectedCategory != "All" {

            resultado = resultado.filter {
                $0.category == selectedCategory
            }
        }

        return resultado
    }

    // MARK: - Filtered Quests

    private var filteredQuests: [Quest] {

        if selectedCategory == "All" {
            return quests
        }

        return quests.filter {
            $0.category == selectedCategory
        }
    }

    // MARK: - Body

    var body: some View {

        VStack(spacing: 0) {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {

                    // MARK: Header

                    HStack(spacing: 12) {

                        Image("WandrLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: 42,
                                height: 42
                            )

                        Text("Events & Quests")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                Color("WandrPrimary")
                            )

                        Spacer()

                        Image(
                            systemName: "bell"
                        )
                        .font(.title3)
                        .foregroundStyle(
                            Color("WandrPrimary")
                        )

                        Image(
                            systemName:
                                "person.circle.fill"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            Color("WandrPrimary")
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                    // MARK: Search

                    HStack(spacing: 10) {

                        Image(
                            systemName:
                                "magnifyingglass"
                        )
                        .foregroundStyle(.secondary)

                        Text(
                            "Search quests in Bogotá."
                        )
                        .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(Color.white)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                    // MARK: Date Filter

                    Menu {

                        Button("This Week") {

                            selectedDateFilter =
                                "This Week"

                            Task {
                                await loadUpcomingEvents()
                            }
                        }

                        Button("All Dates") {

                            selectedDateFilter =
                                "All Dates"

                            Task {
                                await loadAllEvents()
                            }
                        }

                    } label: {

                        HStack {

                            Text(
                                selectedDateFilter
                            )
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(
                                Color("WandrPrimary")
                            )

                            Image(
                                systemName:
                                    "chevron.down"
                            )
                            .font(.caption)
                            .foregroundStyle(
                                Color("WandrSecondary")
                            )

                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // MARK: Categories

                    ScrollView(
                        .horizontal,
                        showsIndicators: false
                    ) {

                        HStack(spacing: 10) {

                            ForEach(
                                categories,
                                id: \.self
                            ) { category in

                                Button {

                                    selectedCategory =
                                        category

                                } label: {

                                    Text(category)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(
                                            selectedCategory == category
                                            ? .white
                                            : Color("WandrPrimary")
                                        )
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 9)
                                        .background(
                                            selectedCategory == category
                                            ? Color("WandrPrimary")
                                            : Color.white
                                        )
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: 14
                                            )
                                        )
                                        .overlay {

                                            if selectedCategory != category {

                                                RoundedRectangle(
                                                    cornerRadius: 14
                                                )
                                                .stroke(
                                                    Color(
                                                        "WandrTertiary"
                                                    )
                                                    .opacity(0.6),
                                                    lineWidth: 1
                                                )
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)

                    // MARK: Featured Experiences

                    VStack(
                        alignment: .leading,
                        spacing: 14
                    ) {

                        HStack {

                            Text(
                                "Featured Experiences"
                            )
                            .font(.headline)
                            .foregroundStyle(
                                Color("WandrPrimary")
                            )

                            Spacer()

                            Button("See all") {

                                selectedCategory = "All"
                                selectedDateFilter = "All Dates"

                                Task {
                                    await loadAllEvents()
                                }
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                Color("WandrSecondary")
                            )
                        }

                        if isLoading {

                            HStack {

                                Spacer()

                                ProgressView()
                                    .tint(
                                        Color(
                                            "WandrPrimary"
                                        )
                                    )

                                Spacer()
                            }
                            .padding(.vertical, 40)

                        } else if let errorMessage {

                            VStack(spacing: 12) {

                                Image(
                                    systemName:
                                        "exclamationmark.triangle"
                                )
                                .font(.title2)
                                .foregroundStyle(
                                    Color(
                                        "WandrSecondary"
                                    )
                                )

                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)

                                Button("Try again") {

                                    Task {

                                        if selectedDateFilter ==
                                            "All Dates" {

                                            await loadAllEvents()

                                        } else {

                                            await loadUpcomingEvents()
                                        }
                                    }
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    Color("WandrPrimary")
                                )
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)

                        } else if filteredEvents.isEmpty {

                            VStack(spacing: 10) {

                                Image(
                                    systemName:
                                        "calendar.badge.exclamationmark"
                                )
                                .font(.title2)
                                .foregroundStyle(
                                    Color("WandrSecondary")
                                )

                                Text(
                                    "No events found."
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)

                        } else {

                            ForEach(
                                filteredEvents
                            ) { event in

                                EventCard(
                                    event: event
                                )
                                .contentShape(
                                    RoundedRectangle(
                                        cornerRadius: 24
                                    )
                                )
                                .onTapGesture {

                                    selectedEvent =
                                        event
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)

                    // MARK: Featured Quests

                    VStack(
                        alignment: .leading,
                        spacing: 14
                    ) {

                        HStack {

                            Text(
                                "Featured Quests"
                            )
                            .font(.headline)
                            .foregroundStyle(
                                Color("WandrPrimary")
                            )

                            Spacer()

                            Text(
                                "\(filteredQuests.count)"
                            )
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                Color("WandrSecondary")
                            )
                        }

                        if questsLoading {

                            HStack {

                                Spacer()

                                ProgressView()
                                    .tint(
                                        Color(
                                            "WandrPrimary"
                                        )
                                    )

                                Spacer()
                            }
                            .padding(.vertical, 30)

                        } else if let questsErrorMessage {

                            VStack(spacing: 12) {

                                Image(
                                    systemName:
                                        "exclamationmark.triangle"
                                )
                                .font(.title2)
                                .foregroundStyle(
                                    Color("WandrSecondary")
                                )

                                Text(
                                    questsErrorMessage
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                                Button("Try again") {

                                    Task {
                                        await loadQuests()
                                    }
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    Color("WandrPrimary")
                                )
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)

                        } else if filteredQuests.isEmpty {

                            Text(
                                "No quests found."
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 20)

                        } else {

                            ScrollView(
                                .horizontal,
                                showsIndicators: false
                            ) {

                                HStack(spacing: 14) {

                                    ForEach(
                                        filteredQuests
                                    ) { quest in

                                        QuestExploreCard(
                                            quest: quest
                                        )
                                        .contentShape(
                                            RoundedRectangle(
                                                cornerRadius: 18
                                            )
                                        )
                                        .onTapGesture {

                                            selectedQuest =
                                                quest
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)

                    // MARK: Quest Radar

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        HStack {

                            Image(
                                systemName:
                                    "location.fill"
                            )
                            .foregroundStyle(
                                Color("WandrSecondary")
                            )

                            Text(
                                "Bogotá Quest Radar"
                            )
                            .font(.headline)
                            .foregroundStyle(
                                Color("WandrPrimary")
                            )
                        }

                        Text(
                            "Discover quests and experiences happening near you."
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Button {

                            selectedTab = .map

                        } label: {

                            HStack {

                                Text(
                                    "Explore nearby quests"
                                )

                                Spacer()

                                Image(
                                    systemName:
                                        "arrow.right"
                                )
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.vertical, 13)
                            .padding(.horizontal, 16)
                            .background(
                                Color("WandrPrimary")
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 14
                                )
                            )
                        }
                    }
                    .padding(18)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .background(
                        Color("WandrSecondary")
                            .opacity(0.12)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 20
                        )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .padding(.top, 4)
            }
            .background(
                Color("WandrBackground")
            )

            BottomNavigationBar(
                selectedTab: $selectedTab
            )
        }
        .background(
            Color("WandrBackground")
        )
        .task {

            await loadUpcomingEvents()
            await loadQuests()
        }


        // MARK: Event Details

        .sheet(
            item: $selectedEvent
        ) { event in

            ExploreEventDetailsView(
                event: event,
                isSaved:
                    savedEventIds.contains(event.id),
                onSave: { event, isSaved in

                    if isSaved {

                        savedEventIds.insert(
                            event.id
                        )

                    } else {

                        savedEventIds.remove(
                            event.id
                        )
                    }
                }
            )
        }
    }

    // MARK: - Load Upcoming Events

    private func loadUpcomingEvents() async {

        isLoading = true
        errorMessage = nil

        do {

            let repository =
                SupabaseQuestRepository()

            events =
                try await repository
                    .getUpcomingEvents()

        } catch {

            print(
                "Supabase upcoming events error:",
                error
            )

            errorMessage =
                "Could not load events."
        }

        isLoading = false
    }

    // MARK: - Load All Events

    private func loadAllEvents() async {

        isLoading = true
        errorMessage = nil

        do {

            let repository =
                SupabaseQuestRepository()

            events =
                try await repository
                    .getAllEvents()

        } catch {

            print(
                "Supabase all events error:",
                error
            )

            errorMessage =
                "Could not load events."
        }

        isLoading = false
    }

    // MARK: - Load Quests

    private func loadQuests() async {

        questsLoading = true
        questsErrorMessage = nil

        do {

            let repository =
                SupabaseQuestRepository()

            quests =
                try await repository
                    .getPersonalizedQuests(
                        userId:
                            "11111111-1111-1111-1111-111111111111"
                    )

        } catch {

            print(
                "Supabase quests error:",
                error
            )

            questsErrorMessage =
                "Could not load quests."
        }

        questsLoading = false
    }
}

// MARK: - Event Card

struct EventCard: View {

    let event: ExploreEvent

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            if let imageURL =
                event.coverImageURL,
               let url =
                URL(string: imageURL) {

                AsyncImage(
                    url: url
                ) { phase in

                    switch phase {

                    case .empty:
                        placeholderImage

                    case .success(let image):

                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:
                        placeholderImage

                    @unknown default:
                        placeholderImage
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: 215
                )
                .clipped()

            } else {

                placeholderImage
            }

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                Text(
                    event.category.uppercased()
                )
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(
                    Color("WandrSecondary")
                )

                Text(event.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        Color("WandrPrimary")
                    )

                HStack(spacing: 6) {

                    Image(
                        systemName: "mappin"
                    )

                    Text(event.location)

                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                HStack(spacing: 6) {

                    Image(
                        systemName: "clock"
                    )

                    Text(event.time)

                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                HStack {

                    Image(
                        systemName: "person.2"
                    )

                    Text(
                        event.participants
                    )

                    Spacer()

                    Text(event.xp)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            Color("WandrSecondary")
                        )
                }
                .font(.subheadline)

                Button {

                    // RSVP will be connected later.

                } label: {

                    Text("Join Event")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(.vertical, 14)
                        .background(
                            Color("WandrPrimary")
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14
                            )
                        )
                }
            }
            .padding(20)
        }
        .background(Color.white)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24
            )
        )
    }

    private var placeholderImage: some View {

        ZStack {

            Color("WandrSecondary")

            Image(
                systemName: event.icon
            )
            .font(
                .system(size: 48)
            )
            .foregroundStyle(.white)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 215
        )
    }
}

// MARK: - Quest Explore Card

struct QuestExploreCard: View {

    let quest: Quest

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            ZStack {

                Color("WandrSecondary")

                Image(
                    systemName:
                        iconForQuestCategory(
                            quest.category
                        )
                )
                .font(
                    .system(size: 42)
                )
                .foregroundStyle(.white)
            }
            .frame(
                width: 190,
                height: 120
            )

            VStack(
                alignment: .leading,
                spacing: 7
            ) {

                Text(
                    quest.category.uppercased()
                )
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(
                    Color("WandrSecondary")
                )

                Text(quest.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        Color("WandrPrimary")
                    )
                    .lineLimit(2)

                HStack(spacing: 5) {

                    Image(
                        systemName: "clock"
                    )

                    Text(
                        "\(quest.duration) min"
                    )

                    Spacer()
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(12)
        }
        .frame(width: 190)
        .background(Color.white)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .shadow(
            color:
                Color.black.opacity(0.06),
            radius: 8,
            y: 3
        )
    }

    private func iconForQuestCategory(
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

        case "games":
            return "gamecontroller"

        default:
            return "sparkles"
        }
    }
}

// MARK: - Event Details

struct ExploreEventDetailsView: View {

    let event: ExploreEvent

    let isSaved: Bool
    let onSave: (ExploreEvent, Bool) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var saved: Bool

    init(
        event: ExploreEvent,
        isSaved: Bool,
        onSave:
            @escaping (ExploreEvent, Bool) -> Void
    ) {

        self.event = event
        self.isSaved = isSaved
        self.onSave = onSave

        _saved =
            State(
                initialValue: isSaved
            )
    }

    private var dateText: String {

        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(identifier: "en_US")

        formatter.dateFormat =
            "EEEE, MMMM d"

        return formatter.string(
            from: event.startsAt
        )
    }

    private var timeText: String {

        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(identifier: "en_US")

        formatter.dateFormat =
            "h:mm a"

        let start =
            formatter.string(
                from: event.startsAt
            )

        guard
            let endDate =
                event.endsAt
        else {
            return start
        }

        let end =
            formatter.string(
                from: endDate
            )

        return "\(start) – \(end)"
    }

    private var capacityText: String? {

        guard
            let capacity =
                event.capacity
        else {
            return nil
        }

        return
            "\(event.attendeeCount) / \(capacity) going"
    }

    var body: some View {

        VStack(
            spacing: 0
        ) {

            // MARK: Custom Header

            ZStack {

                Text("Event Details")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                HStack {

                    Button {

                        dismiss()

                    } label: {

                        Image(
                            systemName:
                                "arrow.left"
                        )
                        .font(.title3)
                        .foregroundStyle(
                            Color("WandrPrimary")
                        )
                    }

                    Spacer()

                    Button {

                        saved.toggle()

                        onSave(
                            event,
                            saved
                        )

                    } label: {

                        Image(
                            systemName:
                                saved
                                ? "bookmark.fill"
                                : "bookmark"
                        )
                        .font(.title3)
                        .foregroundStyle(
                            Color("WandrPrimary")
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 18)

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {

                    // MARK: Cover Image

                    if let imageURL =
                        event.coverImageURL,
                       let url =
                        URL(string: imageURL) {

                        AsyncImage(
                            url: url
                        ) { phase in

                            switch phase {

                            case .empty:
                                eventPlaceholder

                            case .success(let image):

                                image
                                    .resizable()
                                    .scaledToFill()

                            case .failure:
                                eventPlaceholder

                            @unknown default:
                                eventPlaceholder
                            }
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 240,
                            maxHeight: 240
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 24
                            )
                        )
                        .clipped()

                    } else {

                        eventPlaceholder
                    }

                    // MARK: Category

                    Text(
                        event.category.uppercased()
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        Color("WandrSecondary")
                    )

                    // MARK: Title

                    Text(event.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            Color("WandrPrimary")
                        )

                    // MARK: Description

                    Text(event.description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )

                    Divider()

                    // MARK: Location

                    HStack(
                        alignment: .top,
                        spacing: 12
                    ) {

                        Image(
                            systemName:
                                "mappin"
                        )
                        .foregroundStyle(
                            Color("WandrSecondary")
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 3
                        ) {

                            Text("Location")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(
                                event.location
                            )
                            .font(.subheadline)
                            .fontWeight(.medium)
                        }

                        Spacer()
                    }

                    // MARK: Date

                    HStack(
                        alignment: .top,
                        spacing: 12
                    ) {

                        Image(
                            systemName:
                                "calendar"
                        )
                        .foregroundStyle(
                            Color("WandrSecondary")
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 3
                        ) {

                            Text("Date")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(dateText)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Spacer()
                    }

                    // MARK: Time

                    HStack(
                        alignment: .top,
                        spacing: 12
                    ) {

                        Image(
                            systemName:
                                "clock.fill"
                        )
                        .foregroundStyle(
                            Color("WandrSecondary")
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 3
                        ) {

                            Text("Time")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(timeText)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Spacer()
                    }

                    // MARK: Attendees

                    HStack(
                        alignment: .top,
                        spacing: 12
                    ) {

                        Image(
                            systemName:
                                "person.2.fill"
                        )
                        .foregroundStyle(
                            Color("WandrSecondary")
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 3
                        ) {

                            Text("Attendance")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let capacityText {

                                Text(capacityText)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                            } else {

                                Text(
                                    "\(event.attendeeCount) going"
                                )
                                .font(.subheadline)
                                .fontWeight(.medium)
                            }
                        }

                        Spacer()
                    }

                    Divider()

                    // MARK: Reward

                    HStack {

                        Text("Reward")
                            .font(.body)

                        Spacer()

                        Text(event.xp)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                Color("WandrSecondary")
                            )
                    }

                    // MARK: Join Event

                    Button {

                        // RSVP will be connected
                        // to rsvp_event later.

                    } label: {

                        Text("Join Event")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(
                                maxWidth: .infinity
                            )
                            .padding(.vertical, 15)
                            .background(
                                Color("WandrPrimary")
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 14
                                )
                            )
                    }
                }
                .padding(20)
            }
            .background(
                Color("WandrBackground")
            )
        }
        .background(
            Color("WandrBackground")
        )
    }

    private var eventPlaceholder: some View {

        ZStack {

            Color("WandrSecondary")

            Image(
                systemName:
                    event.icon
            )
            .font(
                .system(size: 70)
            )
            .foregroundStyle(.white)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 240,
            maxHeight: 240
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24
            )
        )
    }
}

#Preview {

    ExploreView(
        selectedTab:
            .constant(.explore),

        savedQuestIds:
            .constant([]),

        savedEventIds:
            .constant([]),

        selectedCategory:
            .constant("All")
    )
}
