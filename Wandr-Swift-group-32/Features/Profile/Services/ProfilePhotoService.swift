

import Foundation
import Supabase
import UIKit


class ProfilePhotoService {


    func fetchUser() async throws -> UserProfileDTO {
        try await requireSession()
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


        let legacy = ActiveQuestService.measureLegacyCompression
        let start = ContinuousClock.now
        let jpeg: Data
        if legacy {
            jpeg = UIImage(data: imageData)?.jpegData(compressionQuality: 0.6) ?? imageData
        } else {
            jpeg = await ImageDownsampler.compressForUpload(imageData, maxPixelSize: 800, quality: 0.6)
        }
        let elapsed = ContinuousClock.now - start
        let ms = Int(elapsed.components.seconds * 1000) + Int(elapsed.components.attoseconds / 1_000_000_000_000_000)
        print("""
            [MO1 avatar] \(legacy ? "BEFORE (main thread)" : "AFTER (background thread)") \
            original: \(imageData.count / 1024) KB · processing: \(ms) ms · \
            main thread blocked: \(legacy ? ms : 0) ms · uploaded: \(jpeg.count / 1024) KB
            """)

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
