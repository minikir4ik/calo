import Foundation
import SwiftData

@Model
final class UserSettings {
    var deviceId: String
    var dailyCalorieGoal: Int
    var dailyProteinGoal: Int
    var dailyCarbsGoal: Int
    var dailyFatGoal: Int
    var isPremium: Bool
    var dailyScanCount: Int
    var lastScanDate: Date

    init(
        deviceId: String = UUID().uuidString,
        dailyCalorieGoal: Int = 2000,
        dailyProteinGoal: Int = 150,
        dailyCarbsGoal: Int = 250,
        dailyFatGoal: Int = 65,
        isPremium: Bool = false,
        dailyScanCount: Int = 0,
        lastScanDate: Date = .distantPast
    ) {
        self.deviceId = deviceId
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyProteinGoal = dailyProteinGoal
        self.dailyCarbsGoal = dailyCarbsGoal
        self.dailyFatGoal = dailyFatGoal
        self.isPremium = isPremium
        self.dailyScanCount = dailyScanCount
        self.lastScanDate = lastScanDate
    }

    static let maxFreeScans = 3

    var canScan: Bool {
        isPremium || scansRemainingToday > 0
    }

    var scansRemainingToday: Int {
        if !Calendar.current.isDateInToday(lastScanDate) {
            return Self.maxFreeScans
        }
        return max(0, Self.maxFreeScans - dailyScanCount)
    }

    func recordScan() {
        if !Calendar.current.isDateInToday(lastScanDate) {
            dailyScanCount = 1
            lastScanDate = .now
        } else {
            dailyScanCount += 1
        }
    }
}
