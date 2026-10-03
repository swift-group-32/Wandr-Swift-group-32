import SwiftUI

import Supabase



struct HomeView: View {



    @State private var selectedTab: AppTab = .home

    @State private var savedQuestIds: Set<String> = []

    @State private var showRecommendedQuests = false

    @State private var selectedExploreCategory = "All"

    @State private var savedEventIds: Set<String> = []

    @State private var userName = "User"



    @State private var nearbyQuests: [NearbyQuest] = []

    @State private var nearbyIsLoading = true

    @State private var nearbyErrorMessage: String?



    @StateObject private var discoveryViewModel =

        DiscoveryViewModel(

            repository: SupabaseQuestRepository(),

            strategy: HistoryRecommendationStrategy()

        )



    let categories = [

        ("figure.hiking", "Outdoor"),

        ("fork.knife", "Food"),

        ("paintpalette", "Culture"),

        ("music.note", "Music"),

        ("gamecontroller", "Games")

    ]



    var body: some View {



        Group {



            switch selectedTab {



            case .home:

                homeContent



            case .explore:

                ExploreView(

                    selectedTab: $selectedTab,

                    savedQuestIds: $savedQuestIds,

                    savedEventIds: $savedEventIds,

                    selectedCategory: $selectedExploreCategory

                )



            case .map:

                placeholderView(

                    title: "Map",

                    icon: "map"

                )



            case .saved:
                placeholderView(
                    title: "Saved",
                    icon: "bookmark"
                )



            case .profile:

                placeholderView(

                    title: "Profile",

                    icon: "person"

                )



            case .mysteryQuest:
                placeholderView(
                    title: "Mystery Quest",
                    icon: "sparkles"
                )

            }

        }

    }



    // MARK: - Home Content



    private var homeContent: some View {



        VStack(spacing: 0) {



            ScrollView {



                VStack(

                    alignment: .leading,

                    spacing: 0

                ) {



                    // MARK: Header



                    HStack {



                        HStack(spacing: 12) {



                            Image("WandrLogo")

                                .resizable()

                                .scaledToFit()

                                .frame(

                                    width: 50,

                                    height: 50

                                )



                            Text("Home")

                                .font(.title2)

                                .fontWeight(.bold)

                                .foregroundStyle(

                                    Color("WandrPrimary")

                                )

                        }



                        Spacer()



                        HStack(spacing: 18) {



                            Button {

                                // Notifications

                            } label: {



                                Image(

                                    systemName: "bell"

                                )

                                .font(.title2)

                                .foregroundStyle(

                                    Color("WandrPrimary")

                                )

                            }



                            Button {

                                selectedTab = .profile

                            } label: {



                                Image(

                                    systemName:

                                        "person.circle.fill"

                                )

                                .font(.title2)

                                .foregroundStyle(

                                    Color("WandrPrimary")

                                )

                            }

                        }

                    }

                    .padding(.horizontal, 20)

                    .padding(.top, 18)

                    .padding(.bottom, 22)



                    // MARK: Greeting



                    VStack(

                        alignment: .leading,

                        spacing: 6

                    ) {



                        Text("Hi, \(userName) ")

                            .font(.title)

                            .fontWeight(.bold)

                            .foregroundStyle(

                                Color("WandrPrimary")

                            )



                        HStack(spacing: 8) {



                            Image(

                                systemName:

                                    "mappin.and.ellipse"

                            )

                            .foregroundStyle(

                                Color("WandrSecondary")

                            )



                            Text("Chapinero, Bogotá")

                                .font(.headline)

                                .fontWeight(.regular)

                                .foregroundStyle(

                                    Color("WandrSecondary")

                                )

                        }

                    }

                    .padding(.horizontal, 20)

                    .padding(.bottom, 26)



                    // MARK: Mystery Quest



                    VStack(

                        alignment: .leading,

                        spacing: 14

                    ) {



                        Text("Not sure what to do?")

                            .font(.title2)

                            .fontWeight(.bold)

                            .foregroundStyle(.white)



                        Text("Let us surprise you")

                            .font(.title2)

                            .fontWeight(.bold)

                            .foregroundStyle(.white)



                        Text(

                            "Step out of your routine with a curated surprise spot within 15 min."

                        )

                        .font(.body)

                        .foregroundStyle(

                            .white.opacity(0.85)

                        )

                        .fixedSize(

                            horizontal: false,

                            vertical: true

                        )



                        Button {

                            selectedTab = .mysteryQuest

                        } label: {



                            HStack {



                                Text("Try a Mystery Quest")

                                    .font(.headline)

                                    .fontWeight(.semibold)



                                Spacer()



                                Image(

                                    systemName:

                                        "arrow.right"

                                )

                                .font(.title3)

                            }

                            .foregroundStyle(

                                Color("WandrPrimary")

                            )

                            .padding(.horizontal, 22)

                            .padding(.vertical, 16)

                            .background(

                                Color("WandrBackground")

                            )

                            .clipShape(

                                RoundedRectangle(

                                    cornerRadius: 18

                                )

                            )

                        }

                    }

                    .padding(28)

                    .frame(maxWidth: .infinity)

                    .background(

                        Color("WandrPrimary")

                    )

                    .clipShape(

                        RoundedRectangle(

                            cornerRadius: 30

                        )

                    )

                    .padding(.horizontal, 20)

                    .padding(.bottom, 34)



                    // MARK: Categories



                    VStack(

                        alignment: .leading,

                        spacing: 14

                    ) {



                        Text("Explore by category")

                            .font(.headline)

                            .foregroundStyle(

                                Color("WandrPrimary")

                            )



                        ScrollView(

                            .horizontal,

                            showsIndicators: false

                        ) {



                            HStack(spacing: 12) {



                                ForEach(
                                    categories,
                                    id: \.1
                                ) { category in



                                    Button {

                                        selectedExploreCategory = category.1

                                        selectedTab = .explore

                                    } label: {



                                        HStack(spacing: 8) {



                                            Image(

                                                systemName:

                                                    category.0

                                            )

                                            .font(.headline)



                                            Text(category.1)

                                                .font(.headline)

                                                .fontWeight(.medium)

                                        }

                                        .foregroundStyle(

                                            Color("WandrPrimary")

                                        )

                                        .padding(

                                            .horizontal,

                                            16

                                        )

                                        .padding(

                                            .vertical,

                                            12

                                        )

                                        .overlay(

                                            RoundedRectangle(

                                                cornerRadius: 18

                                            )

                                            .stroke(

                                                Color(

                                                    "WandrTertiary"

                                                ),

                                                lineWidth: 1

                                            )

                                        )

                                    }

                                }

                            }

                        }

                    }

                    .padding(.horizontal, 20)

                    .padding(.bottom, 34)



                    // MARK: Recommended



                    VStack(

                        alignment: .leading,

                        spacing: 14

                    ) {



                        HStack {



                            Text("Recommended for you")

                                .font(.headline)

                                .foregroundStyle(

                                    Color("WandrPrimary")

                                )



                            Spacer()



                            Button("See all") {

                                showRecommendedQuests = true

                            }

                            .font(.caption)

                            .fontWeight(.semibold)

                            .foregroundStyle(

                                Color("WandrSecondary")

                            )

                        }



                        if discoveryViewModel.isLoading {



                            HStack {

                                Spacer()



                                ProgressView()

                                    .tint(

                                        Color("WandrPrimary")

                                    )



                                Spacer()

                            }

                            .frame(height: 180)



                        } else if let errorMessage =

                            discoveryViewModel.errorMessage {



                            HStack {



                                Spacer()



                                VStack(spacing: 10) {



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

                                        .foregroundStyle(

                                            .secondary

                                        )

                                        .multilineTextAlignment(

                                            .center

                                        )



                                    Button("Try again") {



                                        Task {

                                            do {

                                                try await SupabaseManager

                                                    .shared

                                                    .signInForTesting()



                                                userName =

                                                    await SupabaseManager.shared

                                                        .getCurrentUserName()



                                                if let user = SupabaseManager.shared.client.auth.currentUser {

                                                    await discoveryViewModel.loadRecommendations(

                                                        userId: user.id.uuidString,

                                                        savedQuestIds: savedQuestIds

                                                    )

                                                }



                                                await loadNearbyQuests()



                                            } catch {

                                                print(

                                                    "Supabase login error:",

                                                    error

                                                )

                                            }

                                        }

                                    }

                                    .font(.subheadline)

                                    .fontWeight(.semibold)

                                    .foregroundStyle(

                                        Color("WandrPrimary")

                                    )

                                }



                                Spacer()

                            }

                            .frame(height: 180)



                        } else if discoveryViewModel.quests.isEmpty {



                            HStack {



                                Spacer()



                                VStack(spacing: 8) {



                                    Image(

                                        systemName:

                                            "sparkles"

                                    )

                                    .font(.title2)

                                    .foregroundStyle(

                                        Color(

                                            "WandrSecondary"

                                        )

                                    )



                                    Text(

                                        "No recommendations yet"

                                    )

                                    .font(.subheadline)

                                    .foregroundStyle(

                                        .secondary

                                    )

                                }



                                Spacer()

                            }

                            .frame(height: 180)



                        } else {



                            ScrollView(

                                .horizontal,

                                showsIndicators: false

                            ) {



                                HStack(spacing: 16) {



                                    ForEach(

                                        discoveryViewModel.quests

                                    ) { quest in



                                        RecommendedQuestCard(

                                            title: quest.title,

                                            category:

                                                quest.category,

                                            duration:

                                                "\(quest.duration) min",

                                            location:

                                                "Chapinero",

                                            icon:

                                                iconForCategory(

                                                    quest.category

                                                )

                                        ) {

                                        }

                                    }

                                }

                            }

                        }

                    }

                    .padding(.horizontal, 20)

                    .padding(.bottom, 30)



                    // MARK: Nearby



                    VStack(

                        alignment: .leading,

                        spacing: 14

                    ) {



                        HStack {



                            Text("Nearby")

                                .font(.headline)

                                .foregroundStyle(

                                    Color("WandrPrimary")

                                )



                            Spacer()



                            Button("See all") {

                                selectedTab = .map

                            }

                            .font(.caption)

                            .fontWeight(.semibold)

                            .foregroundStyle(

                                Color("WandrSecondary")

                            )

                        }



                        if nearbyIsLoading {



                            HStack {



                                Spacer()



                                ProgressView()

                                    .tint(

                                        Color("WandrPrimary")

                                    )



                                Spacer()

                            }

                            .frame(height: 180)



                        } else if let errorMessage =

                            nearbyErrorMessage {



                            VStack(spacing: 10) {



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

                                    .foregroundStyle(

                                        .secondary

                                    )

                                    .multilineTextAlignment(

                                        .center

                                    )



                                Button("Try again") {



                                    Task {

                                        await loadNearbyQuests()

                                    }

                                }

                                .font(.subheadline)

                                .fontWeight(.semibold)

                                .foregroundStyle(

                                    Color("WandrPrimary")

                                )

                            }

                            .frame(

                                maxWidth: .infinity,

                                minHeight: 180

                            )



                        } else if nearbyQuests.isEmpty {



                            VStack(spacing: 10) {



                                Image(

                                    systemName:

                                        "location.slash"

                                )

                                .font(.title2)

                                .foregroundStyle(

                                    Color(

                                        "WandrSecondary"

                                    )

                                )



                                Text("No nearby quests")

                                    .font(.subheadline)

                                    .foregroundStyle(

                                        .secondary

                                    )

                            }

                            .frame(

                                maxWidth: .infinity,

                                minHeight: 180

                            )



                        } else {



                            ForEach(

                                nearbyQuests

                            ) { quest in



                                Button {

                                } label: {



                                    HStack(spacing: 14) {



                                        ZStack {



                                            RoundedRectangle(

                                                cornerRadius: 14

                                            )

                                            .fill(

                                                Color(

                                                    "WandrSecondary"

                                                )

                                            )



                                            Image(

                                                systemName:

                                                    "mappin.and.ellipse"

                                            )

                                            .foregroundStyle(

                                                .white

                                            )

                                        }

                                        .frame(

                                            width: 54,

                                            height: 54

                                        )



                                        VStack(

                                            alignment: .leading,

                                            spacing: 4

                                        ) {



                                            Text(quest.title)

                                                .font(

                                                    .subheadline

                                                )

                                                .fontWeight(

                                                    .semibold

                                                )

                                                .foregroundStyle(

                                                    Color(

                                                        "WandrPrimary"

                                                    )

                                                )

                                                .lineLimit(1)



                                            Text(

                                                "\(quest.distance, specifier: "%.1f") km · \(quest.location)"

                                            )

                                            .font(.caption)

                                            .foregroundStyle(

                                                Color(

                                                    "WandrSecondary"

                                                )

                                            )



                                            HStack(spacing: 5) {



                                                Image(

                                                    systemName:

                                                        "clock"

                                                )



                                                Text(

                                                    "\(quest.duration) min"

                                                )

                                            }

                                            .font(.caption2)

                                            .foregroundStyle(

                                                .secondary

                                            )

                                        }



                                        Spacer()



                                        Image(

                                            systemName:

                                                "chevron.right"

                                        )

                                        .foregroundStyle(

                                            Color(

                                                "WandrSecondary"

                                            )

                                        )

                                    }

                                    .padding(12)

                                    .background(

                                        Color.white

                                    )

                                    .clipShape(

                                        RoundedRectangle(

                                            cornerRadius: 18

                                        )

                                    )

                                }

                                .buttonStyle(.plain)

                            }

                        }

                    }

                    .padding(.horizontal, 20)

                    .padding(.bottom, 30)

                }

            }

            .background(

                Color("WandrBackground")

            )



            // MARK: Bottom Navigation



            BottomNavigationBar(

                selectedTab: $selectedTab

            )

        }

        .background(

            Color("WandrBackground")

        )



        // MARK: Recommended Quests



        .fullScreenCover(

            isPresented: $showRecommendedQuests

        ) {

            RecommendedQuestsView(

                quests: discoveryViewModel.quests,

                savedQuestIds: $savedQuestIds,

                selectedTab: $selectedTab

            )

        }



        // MARK: Supabase



        .task {

            do {



                try await SupabaseManager.shared

                    .signInForTesting()



                userName =

                    await SupabaseManager.shared

                        .getCurrentUserName()



                if let user = SupabaseManager.shared.client.auth.currentUser {

                    await discoveryViewModel.loadRecommendations(

                        userId: user.id.uuidString,

                        savedQuestIds: savedQuestIds

                    )

                }



                await loadNearbyQuests()



            } catch {



                print(

                    "Supabase login error:",

                    error

                )

            }

        }

    }



    // MARK: - Load Nearby Quests



    private func loadNearbyQuests() async {



        nearbyIsLoading = true

        nearbyErrorMessage = nil



        do {



            let repository =

                SupabaseQuestRepository()



            nearbyQuests =

                try await repository.getNearbyQuests(

                    latitude: 4.6533,

                    longitude: -74.0636,

                    radius: 5

                )



        } catch {



            print(

                "Supabase nearby quests error:",

                error

            )



            nearbyErrorMessage =

                "Could not load nearby quests."

        }



        nearbyIsLoading = false

    }



    // MARK: - Helpers



    private func iconForCategory(

        _ category: String

    ) -> String {



        switch category.lowercased() {



        case "outdoor":

            return "figure.hiking"



        case "food":

            return "fork.knife"



        case "culture", "art":

            return "paintpalette"



        case "music":

            return "music.note"



        case "games":

            return "gamecontroller"



        default:

            return "sparkles"

        }

    }



    private func placeholderView(

        title: String,

        icon: String

    ) -> some View {



        VStack(spacing: 16) {



            Image(systemName: icon)

                .font(.system(size: 40))

                .foregroundStyle(

                    Color("WandrPrimary")

                )



            Text(title)

                .font(.title2)

                .fontWeight(.bold)

                .foregroundStyle(

                    Color("WandrPrimary")

                )

        }

        .frame(

            maxWidth: .infinity,

            maxHeight: .infinity

        )

        .background(

            Color("WandrBackground")

        )

        .overlay(

            VStack {



                Spacer()



                BottomNavigationBar(

                    selectedTab: $selectedTab

                )

            }

        )

    }

}



// MARK: - Recommended Quest Card



struct RecommendedQuestCard: View {



    let title: String

    let category: String

    let duration: String

    let location: String

    let icon: String

    let action: () -> Void



    var body: some View {



        Button(action: action) {



            VStack(

                alignment: .leading,

                spacing: 0

            ) {



                ZStack {



                    Color("WandrSecondary")



                    Image(systemName: icon)

                        .font(

                            .system(size: 38)

                        )

                        .foregroundStyle(.white)

                }

                .frame(

                    width: 230,

                    height: 120

                )



                VStack(

                    alignment: .leading,

                    spacing: 7

                ) {



                    Text(title)

                        .font(.headline)

                        .fontWeight(.bold)

                        .foregroundStyle(

                            Color("WandrPrimary")

                        )

                        .lineLimit(2)



                    Text(category)

                        .font(.caption)

                        .fontWeight(.semibold)

                        .foregroundStyle(

                            Color("WandrSecondary")

                        )



                    HStack {



                        Label(

                            duration,

                            systemImage: "clock"

                        )



                        Spacer()



                        Label(

                            location,

                            systemImage: "mappin"

                        )

                    }

                    .font(.caption)

                    .foregroundStyle(.secondary)

                }

                .padding(14)

            }

            .frame(width: 230)

            .background(Color.white)

            .clipShape(

                RoundedRectangle(

                    cornerRadius: 20

                )

            )

        }

        .buttonStyle(.plain)

    }

}



#Preview {

    HomeView()

}
