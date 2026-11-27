

import XCTest
import UIKit
@testable import Wandr_Swift_group_32

@MainActor
final class MicroOptimizationPerformanceTests: XCTestCase {

    
    private static let cameraPhoto: Data = {
        let size = CGSize(width: 4032, height: 3024)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            for i in 0..<60 {
                UIColor(hue: CGFloat(i) / 60, saturation: 0.7, brightness: 0.9, alpha: 1).setFill()
                context.fill(CGRect(x: CGFloat(i) * 67, y: 0, width: 67, height: size.height))
            }
        }
        return image.jpegData(compressionQuality: 0.95)!
    }()

    
    private func legacyCompress(_ data: Data) -> Data {
        UIImage(data: data)?.jpegData(compressionQuality: 0.7) ?? data
    }

    func testMO1_before_fullSizeEncodingOnMainThread() {
        let data = Self.cameraPhoto
        var output = 0
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            output = legacyCompress(data).count
        }
        print("MO1 before: upload size =", output / 1024, "KB")
    }

    func testMO1_after_downsampledEncoding() {
        let data = Self.cameraPhoto
        var output = 0
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            output = ImageDownsampler.downsample(data, maxPixelSize: 1600)?
                .jpegData(compressionQuality: 0.7)?.count ?? 0
        }
        print("MO1 after: upload size =", output / 1024, "KB")
    }


    private static let achievements: [Achievement] = (0..<40).map { i in
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return Achievement(id: "\(i)", name: "Badge \(i)", description: nil,
                           unlocked: i % 4 != 0, earnedOn: "\(months[i % 12]) \(String(format: "%02d", i % 28 + 1))")
    }

    private func legacyLatestBadge(_ achievements: [Achievement]) -> Achievement? {
        func earnedDate(_ achievement: Achievement) -> Date {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "MMM dd"
            guard let text = achievement.earnedOn, let parsed = formatter.date(from: text) else { return .distantPast }
            let calendar = Calendar.current
            var parts = calendar.dateComponents([.month, .day], from: parsed)
            parts.year = calendar.component(.year, from: Date())
            guard var date = calendar.date(from: parts) else { return .distantPast }
            if date > Date() { date = calendar.date(byAdding: .year, value: -1, to: date) ?? date }
            return date
        }
        let unlocked = achievements.filter { $0.unlocked }
        return unlocked.max { earnedDate($0) < earnedDate($1) }
    }


    func testMO2_before_formatterPerComparison() {
        let achievements = Self.achievements
        measure {
            for _ in 0..<100 { _ = legacyLatestBadge(achievements) }
        }
    }

    func testMO2_after_sharedFormatterComputedOnce() {
        let achievements = Self.achievements
        measure {
            
            let badge = ProfileViewModel.findLatestBadge(in: achievements)
            for _ in 0..<100 { _ = badge }
        }
    }

    func testMO2_sameResultAsBefore() {
        XCTAssertEqual(ProfileViewModel.findLatestBadge(in: Self.achievements)?.id,
                       legacyLatestBadge(Self.achievements)?.id)
    }
}
