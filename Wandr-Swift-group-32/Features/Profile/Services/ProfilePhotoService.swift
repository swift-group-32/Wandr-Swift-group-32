import Foundation
import Supabase
import UIKit


class ProfilePhotoService {


    func fetchUser() async throws -> UserProfileDTO {
        try await signInTestUserIfNeeded()
        let userId = try await supabase.auth.session.user.id

        let response = try await supabase
            .from("users")
            .select("id, name, profile_picture")
            .eq("id", value: userId)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(UserProfileDTO.self, from: response.data)
    }


    func uploadPhoto(imageData: Data) async throws -> String {
        let userId = try await supabase.auth.session.user.id.uuidString.lowercased()


        let path = "\(userId)/avatar.jpg"


        let jpeg = UIImage(data: imageData)?.jpegData(compressionQuality: 0.6) ?? imageData

        try await supabase.storage
            .from("avatars")
            .upload(path, data: jpeg, options: FileOptions(contentType: "image/jpeg", upsert: true))

        
        let publicURL = try supabase.storage.from("avatars").getPublicURL(path: path)
        let link = "\(publicURL.absoluteString)?v=\(Int(Date().timeIntervalSince1970))"

        try await savePictureLink(link, userId: userId)
        return link
    }

    func removePhoto() async throws {
        let userId = try await supabase.auth.session.user.id.uuidString.lowercased()
        try await savePictureLink(nil, userId: userId)
    }

    private func savePictureLink(_ link: String?, userId: String) async throws {
        try await supabase
            .from("users")
            .update(["profile_picture": link])
            .eq("id", value: userId)
            .execute()
    }
}
