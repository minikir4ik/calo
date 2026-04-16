import Foundation
import SwiftData

@Model
final class UserSettings {
    var deviceId: String
    var firstName: String
    var dailyCalorieGoal: Int
    var dailyProteinGoal: Int
    var dailyCarbsGoal: Int
    var dailyFatGoal: Int
    var isPremium: Bool
    var dailyScanCount: Int
    var lastScanDate: Date
    var dailyWaterGlasses: Int
    var lastWaterDate: Date
    var waterGoal: Int

    init(
        deviceId: String = UUID().uuidString,
        firstName: String = "",
        dailyCalorieGoal: Int = 2000,
        dailyProteinGoal: Int = 150,
        dailyCarbsGoal: Int = 250,
        dailyFatGoal: Int = 65,
        isPremium: Bool = false,
        dailyScanCount: Int = 0,
        lastScanDate: Date = .distantPast,
        dailyWaterGlasses: Int = 0,
        lastWaterDate: Date = .distantPast,
        waterGoal: Int = 8
    ) {
        self.deviceId = deviceId
        self.firstName = firstName
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyProteinGoal = dailyProteinGoal
        self.dailyCarbsGoal = dailyCarbsGoal
        self.dailyFatGoal = dailyFatGoal
        self.isPremium = isPremium
        self.dailyScanCount = dailyScanCount
        self.lastScanDate = lastScanDate
        self.dailyWaterGlasses = dailyWaterGlasses
        self.lastWaterDate = lastWaterDate
        self.waterGoal = waterGoal
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

    var waterGlassesToday: Int {
        if !Calendar.current.isDateInToday(lastWaterDate) {
            return 0
        }
        return dailyWaterGlasses
    }

    func addWater() {
        if !Calendar.current.isDateInToday(lastWaterDate) {
            dailyWaterGlasses = 1
            lastWaterDate = .now
        } else {
            dailyWaterGlasses += 1
        }
    }

    func removeWater() {
        if Calendar.current.isDateInToday(lastWaterDate) {
            dailyWaterGlasses = max(0, dailyWaterGlasses - 1)
        }
    }
}
