import Foundation
import SwiftData

enum DashboardIntelligenceService {

    struct Insight {
        let title: String
        let subtitle: String
    }

    static func getDailyInsight(
        entries: [FoodEntry],
        calorieGoal: Int,
        proteinGoal: Int,
        carbsGoal: Int,
        fatGoal: Int
    ) -> Insight {
        let totalCal = entries.reduce(0.0) { $0 + $1.calories }
        let totalProtein = entries.reduce(0.0) { $0 + $1.protein }
        let totalCarbs = entries.reduce(0.0) { $0 + $1.carbs }

        let hour = Calendar.current.component(.hour, from: .now)

        // No entries yet
        if entries.isEmpty {
            if hour < 11 {
                return Insight(
                    title: "Scan your first meal to get started",
                    subtitle: "Your personalized tracking begins now"
                )
            } else {
                return Insight(
                    title: "No meals logged yet today",
                    subtitle: "Scan something to start tracking"
                )
            }
        }

        let calRemaining = Double(calorieGoal) - totalCal
        let proteinRemaining = Double(proteinGoal) - totalProtein

        // Over budget
        if calRemaining < -200 {
            return Insight(
                title: "You're \(Int(-calRemaining)) cal over target",
                subtitle: "Consider lighter meals for the rest of the day"
            )
        }

        // Evening — close to target
        if hour >= 18 && calRemaining > 0 && calRemaining < 400 {
            return Insight(
                title: "Almost there — \(Int(calRemaining)) cal to go",
                subtitle: "A light snack will close out the day"
            )
        }

        // Protein focused
        if proteinRemaining > 40 {
            return Insight(
                title: "Need \(Int(proteinRemaining))g more protein today",
                subtitle: "Try chicken, eggs, or Greek yogurt"
            )
        }

        // Good deficit
        if calRemaining > 300 && hour >= 14 {
            return Insight(
                title: "You're \(Int(calRemaining)) cal under target",
                subtitle: "Good deficit day — keep it going"
            )
        }

        // Carbs low
        let carbsRemaining = Double(carbsGoal) - totalCarbs
        if carbsRemaining > Double(carbsGoal) * 0.6 && entries.count >= 2 {
            return Insight(
                title: "Low on carbs — \(Int(carbsRemaining))g remaining",
                subtitle: "Great if you're doing low-carb, otherwise fuel up"
            )
        }

        // Default
        return Insight(
            title: "\(Int(totalCal)) cal logged — \(Int(calRemaining)) remaining",
            subtitle: "You're on track for the day"
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
