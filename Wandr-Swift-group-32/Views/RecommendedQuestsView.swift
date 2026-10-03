//
//  RecommendedQuestsView.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 1/10/26.
//

import SwiftUI

struct RecommendedQuestsView: View {

    let quests: [Quest]

    @Binding var savedQuestIds: Set<String>

    @Binding var selectedTab: AppTab

    @Environment(\.dismiss) private var dismiss

    var body: some View {

        VStack(spacing: 0) {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {

                    // MARK: Header

                    HStack(spacing: 12) {

                        Button {
                            dismiss()
                        } label: {

                            Image(
                                systemName: "chevron.left"
                            )
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                Color("WandrPrimary")
                            )
                        }

                        Image("WandrLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: 42,
                                height: 42
                            )

                        Text("Explore Quests")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                Color("WandrPrimary")
                            )

                        Spacer()

                        Image(
                            systemName: "person.circle.fill"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            Color("WandrPrimary")
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 22)

                    // MARK: Curated For You

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text("Curated For You")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                Color("WandrPrimary")
                            )

                        Text(
                            "Based on your activity and interests"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                    // MARK: Spotlight

                    if let spotlightQuest = quests.first {

                        VStack(
                            alignment: .leading,
                            spacing: 10
                        ) {

                            HStack {

                                Text("⚡ SPOTLIGHT SIDE QUEST")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(
                                        Color("WandrSecondary")
                                    )

                                Spacer()

                                Text("For you")
                                    .font(.caption)
                                    .foregroundStyle(
                                        .secondary
                                    )
                            }

                            VStack(
                                alignment: .leading,
                                spacing: 0
                            ) {

                                ZStack(
                                    alignment: .bottomLeading
                                ) {

                                    RoundedRectangle(
                                        cornerRadius: 20
                                    )
                                    .fill(
                                        Color(
                                            "WandrSecondary"
                                        )
                                    )
                                    .frame(
                                        height: 180
                                    )

                                    VStack(
                                        alignment: .leading,
                                        spacing: 5
                                    ) {

                                        Text(
                                            spotlightQuest.category
                                        )
                                        .font(.caption)
                                        .fontWeight(
                                            .semibold
                                        )
                                        .foregroundStyle(
                                            .white
                                        )

                                        Text(
                                            spotlightQuest.title
                                        )
                                        .font(.title3)
                                        .fontWeight(
                                            .bold
                                        )
                                        .foregroundStyle(
                                            .white
                                        )
                                    }
                                    .padding(18)
                                }

                                VStack(
                                    alignment: .leading,
                                    spacing: 6
                                ) {

                                    Text(
                                        spotlightQuest.title
                                    )
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        Color(
                                            "WandrPrimary"
                                        )
                                    )

                                    Text(
                                        spotlightQuest.description
                                    )
                                    .font(.subheadline)
                                    .foregroundStyle(
                                        .secondary
                                    )
                                    .lineLimit(2)

                                    HStack {

                                        Label(
                                            "\(spotlightQuest.duration) min",
                                            systemImage: "clock"
                                        )

                                        Spacer()

                                        Button {

                                            if savedQuestIds.contains(
                                                spotlightQuest.id
                                            ) {

                                                savedQuestIds.remove(
                                                    spotlightQuest.id
                                                )

                                            } else {

                                                savedQuestIds.insert(
                                                    spotlightQuest.id
                                                )
                                            }

                                        } label: {

                                            Image(
                                                systemName:
                                                    savedQuestIds.contains(
                                                        spotlightQuest.id
                                                    )
                                                    ? "bookmark.fill"
                                                    : "bookmark"
                                            )
                                            .foregroundStyle(
                                                Color(
                                                    "WandrPrimary"
                                                )
                                            )
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(
                                        .secondary
                                    )
                                }
                                .padding(16)
                            }
                            .background(
                                Color.white
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 20
                                )
                            )
                        }
                        .padding(.horizontal, 20)
                    }

                    // MARK: Curated Micro-Tracks

                    VStack(
                        alignment: .leading,
                        spacing: 14
                    ) {

                        HStack {

                            Text("Curated Micro-Tracks")
                                .font(.headline)
                                .foregroundStyle(
                                    Color("WandrPrimary")
                                )

                            Spacer()

                            Text(
                                "\(quests.count)"
                            )
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                Color("WandrSecondary")
                            )
                        }

                        ForEach(
                            Array(
                                quests.dropFirst()
                            )
                        ) { quest in

                            HStack(spacing: 12) {

                                ZStack {

                                    RoundedRectangle(
                                        cornerRadius: 12
                                    )
                                    .fill(
                                        Color(
                                            "WandrSecondary"
                                        )
                                    )

                                    Image(
                                        systemName:
                                            iconForCategory(
                                                quest.category
                                            )
                                    )
                                    .foregroundStyle(
                                        .white
                                    )
                                }
                                .frame(
                                    width: 64,
                                    height: 64
                                )

                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {

                                    Text(quest.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(
                                            Color(
                                                "WandrPrimary"
                                            )
                                        )
                                        .lineLimit(2)

                                    Text(
                                        "\(quest.duration) min · \(quest.category)"
                                    )
                                    .font(.caption)
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 30)
                }
            }

            BottomNavigationBar(
                selectedTab: $selectedTab
            )
        }
        .background(
            Color("WandrBackground")
        )
    }

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
}

#Preview {

    RecommendedQuestsView(
        quests: [],
        savedQuestIds: .constant([]),
        selectedTab: .constant(.home)
    )
}
