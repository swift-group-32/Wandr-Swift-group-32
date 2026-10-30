//
//  SponsoredQuestViewModel.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 30/10/26.
//

import Foundation
import Combine

@MainActor
final class SponsoredQuestViewModel: ObservableObject {

    @Published var activeUser: ActiveUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: SponsoredQuestRepository

    init(repository: SponsoredQuestRepository) {
        self.repository = repository
    }

    func loadCurrentUser() async {
        isLoading = true
        errorMessage = nil

        do {
            activeUser = try await repository.fetchCurrentUserActivity()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
