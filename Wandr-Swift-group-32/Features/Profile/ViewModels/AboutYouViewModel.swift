import Foundation
import Combine

class AboutYouViewModel: ObservableObject {

    
    @Published var ageRange = ""
    @Published var occupation = ""
    @Published var notificationsEnabled = true

    
    @Published var savedInfo: AboutYouDTO? = nil

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var message: String? = nil
    @Published var didSave = false

    static let preferNotToSay = "prefer_not_to_say"

    let ageOptions = ["18-24", "25-34", "35-44", "45+"]
    let occupationOptions = ["student", "employee", "freelancer", "other"]

    let service = AboutYouService()

    func load() async {
        if !NetworkMonitor.shared.isConnected {
            message = "You're offline. Connect to the internet to see and edit this information."
            return
        }

        isLoading = true
        do {
            let info = try await service.fetch()
            savedInfo = info
            ageRange = info.age_range ?? ""
            occupation = info.occupation ?? ""
            notificationsEnabled = info.notifications_enabled ?? true
            message = nil
        } catch {
            message = "Could not load your information. Try again."
        }
        isLoading = false
    }

    func save() async {
        
        if !NetworkMonitor.shared.isConnected {
            message = "You're offline. Your answers were not saved, try again when you have internet."
            return
        }

        isSaving = true
        let info = AboutYouDTO(
            age_range: ageRange.isEmpty ? nil : ageRange,
            occupation: occupation.isEmpty ? nil : occupation,
            notifications_enabled: notificationsEnabled
        )
        do {
            try await service.save(info)
            savedInfo = info
            message = nil
            didSave = true
        } catch {
            message = "Could not save your answers. Try again."
        }
        isSaving = false
    }

    func missingItems(hasPhoto: Bool) -> [String] {
        var missing: [String] = []
        if !hasPhoto { missing.append("a profile photo") }
        if savedInfo?.age_range == nil { missing.append("your age range") }
        if savedInfo?.occupation == nil { missing.append("your occupation") }
        return missing
    }

    
    func completion(hasPhoto: Bool) -> Double {
        let total = 3.0
        return (total - Double(missingItems(hasPhoto: hasPhoto).count)) / total
    }


    func label(_ value: String) -> String {
        value.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
