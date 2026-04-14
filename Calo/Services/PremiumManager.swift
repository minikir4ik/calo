import Foundation
import RevenueCat

@MainActor
final class PremiumManager: ObservableObject {
    static let premiumEntitlementID = "premium"
    static let maxFreeScans = 3
    static let maxPremiumScans = 30

    @Published var isPremium = false
    @Published var dailyScansRemaining: Int = PremiumManager.maxFreeScans

    private var dailyScanCount = 0
    private var lastScanDate: Date = .distantPast

    var dailyScanLimit: Int {
        isPremium ? Self.maxPremiumScans : Self.maxFreeScans
    }

    init() {
        loadScanData()
        resetIfNewDay()

        Purchases.shared.delegate = self

        Task {
            await checkPremiumStatus()
        }
    }

    func checkPremiumStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updatePremium(from: customerInfo)
        } catch {
            // Keep current state on error
        }
    }

    func canScan() -> Bool {
        resetIfNewDay()
        return isPremium || dailyScansRemaining > 0
    }

    func recordScan() {
        resetIfNewDay()
        dailyScanCount += 1
        dailyScansRemaining = max(0, dailyScanLimit - dailyScanCount)
        lastScanDate = .now
        saveScanData()
    }

    // MARK: - Private

    private func updatePremium(from customerInfo: CustomerInfo) {
        let wasPremiun = isPremium
        isPremium = customerInfo.entitlements[Self.premiumEntitlementID]?.isActive == true
        if isPremium != wasPremiun {
            resetIfNewDay()
        }
    }

    private func resetIfNewDay() {
        if !Calendar.current.isDateInToday(lastScanDate) {
            dailyScanCount = 0
            lastScanDate = .now
            saveScanData()
        }
        dailyScansRemaining = max(0, dailyScanLimit - dailyScanCount)
    }

    private let scanCountKey = "PremiumManager.dailyScanCount"
    private let scanDateKey = "PremiumManager.lastScanDate"

    private func loadScanData() {
        dailyScanCount = UserDefaults.standard.integer(forKey: scanCountKey)
        let interval = UserDefaults.standard.double(forKey: scanDateKey)
        lastScanDate = interval > 0 ? Date(timeIntervalSince1970: interval) : .distantPast
    }

    private func saveScanData() {
        UserDefaults.standard.set(dailyScanCount, forKey: scanCountKey)
        UserDefaults.standard.set(lastScanDate.timeIntervalSince1970, forKey: scanDateKey)
    }
}

// MARK: - PurchasesDelegate

extension PremiumManager: @preconcurrency PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            updatePremium(from: customerInfo)
        }
    }
}
