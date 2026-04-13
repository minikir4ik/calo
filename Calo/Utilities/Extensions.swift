import Foundation
import UIKit

extension Double {
    func rounded(to places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }

    var wholeOrOne: String {
        self.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%.1f", self)
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var shortWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
}

extension UIImage {
    func compressed(maxKB: Int = 500) -> Data? {
        var compression: CGFloat = 0.8
        var data = jpegData(compressionQuality: compression)
        while let d = data, d.count > maxKB * 1024, compression > 0.1 {
            compression -= 0.1
            data = jpegData(compressionQuality: compression)
        }
        return data
    }
}
