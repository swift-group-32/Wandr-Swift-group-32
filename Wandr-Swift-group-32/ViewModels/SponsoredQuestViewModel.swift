//
//  SponsoredQuestViewModel.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 30/10/26.
//

import Foundation
import Combine
import Supabase

@MainActor
final class SponsoredQuestViewModel: ObservableObject {

    @Published var activeUser: ActiveUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: SponsoredQuestRepository
    
    private let cache = SponsoredQuestCache.shared
    private let localStorage = SponsoredQuestLocalStorage.shared

    init(repository: SponsoredQuestRepository) {
        self.repository = repository
    }

    func loadCurrentUser() async {
        isLoading = true
        errorMessage = nil

        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id.uuidString

            if let cachedUser = cache.load(userId: userId) {
                activeUser = cachedUser
                isLoading = false
            }

            if activeUser == nil {
                if let localUser = try await localStorage.load() {
                    activeUser = localUser
                    cache.save(localUser)
                    isLoading = false
                }
            }

            let freshUser = try await repository.fetchCurrentUserActivity()

            if let freshUser {
                activeUser = freshUser
                cache.save(freshUser)
                try await localStorage.save(freshUser)
            }

        } catch {
            
            if activeUser == nil {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
}
