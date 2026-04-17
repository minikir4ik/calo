import Foundation
import SwiftData

enum DashboardIntelligenceService {

    struct Insight {
        let message: String
        let icon: String
    }

    static func getDailyInsight(
        entries: [FoodEntry],
        name: String?,
        calorieGoal: Int,
        proteinGoal: Int,
        carbsGoal: Int,
        fatGoal: Int
    ) -> Insight {
        let totalCal = entries.reduce(0.0) { $0 + $1.calories }
        let totalProtein = entries.reduce(0.0) { $0 + $1.protein }
        let totalCarbs = entries.reduce(0.0) { $0 + $1.carbs }

        let hour = Calendar.current.component(.hour, from: .now)
        let displayName = (name != nil && !name!.isEmpty) ? ", \(name!)" : ""

        // No entries yet
        if entries.isEmpty {
            if hour < 11 {
                return Insight(
                    message: "Start your day right\(displayName) — scan your first meal",
                    icon: "sunrise.fill"
                )
            } else {
                return Insight(
                    message: "No meals logged yet today — scan something to start tracking",
                    icon: "fork.knife"
                )
            }
        }

        let calRemaining = Double(calorieGoal) - totalCal
        let proteinRemaining = Double(proteinGoal) - totalProtein

        // All goals met
        if totalCal >= Double(calorieGoal) * 0.9 &&
           totalCal <= Double(calorieGoal) * 1.1 &&
           totalProtein >= Double(proteinGoal) * 0.85 {
            return Insight(
                message: "Goals complete! Amazing day\(displayName)",
                icon: "party.popper.fill"
            )
        }

        // Over budget
        if calRemaining < -200 {
            return Insight(
                message: "You're \(Int(-calRemaining)) cal over target — consider a lighter dinner",
                icon: "flame.fill"
            )
        }

        // Evening — close to target
        if hour >= 18 && calRemaining > 0 && calRemaining < 400 {
            return Insight(
                message: "Almost there — \(Int(calRemaining)) cal to go",
                icon: "checkmark.circle"
            )
        }

        // Protein focused
        if proteinRemaining > 40 {
            return Insight(
                message: "You need \(Int(proteinRemaining))g more protein today",
                icon: "bolt.fill"
            )
        }

        // Good deficit
        if calRemaining > 300 && hour >= 14 {
            return Insight(
                message: "You're \(Int(calRemaining)) cal under target — keep it going",
                icon: "arrow.down.right"
            )
        }

        // Carbs low
        let carbsRemaining = Double(carbsGoal) - totalCarbs
        if carbsRemaining > Double(carbsGoal) * 0.6 && entries.count >= 2 {
            return Insight(
                message: "Low on carbs — \(Int(carbsRemaining))g remaining",
                icon: "leaf.fill"
            )
        }

        // Default — on track
        return Insight(
            message: "You're crushing it today — \(Int(calRemaining)) cal to go",
            icon: "sparkles"
        )
    }

    static func getStreakCount(entries: [FoodEntry]) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: .now)

        while true {
            let dayStart = checkDate
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let hasEntry = entries.contains { $0.timestamp >= dayStart && $0.timestamp < dayEnd }

            if hasEntry {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else {
                break
            }
        }

        return streak
    }

    static func getWeeklyData(entries: [FoodEntry]) -> [DayCalories] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date)!
            let dayEntries = entries.filter { $0.timestamp >= date && $0.timestamp < nextDay }
            return DayCalories(
                date: date,
                calories: dayEntries.reduce(0.0) { $0 + $1.calories },
                protein: dayEntries.reduce(0.0) { $0 + $1.protein },
                carbs: dayEntries.reduce(0.0) { $0 + $1.carbs },
                fat: dayEntries.reduce(0.0) { $0 + $1.fat },
                weekday: date.shortWeekday
            )
        }
    }

    static func greeting(name: String? = nil) -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        let timeGreeting: String
        switch hour {
        case 5..<12: timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        case 17..<22: timeGreeting = "Good evening"
        default: timeGreeting = "Good night"
        }

        if let name, !name.isEmpty {
            return "\(timeGreeting), \(name)"
        }
        return timeGreeting
    }
}
