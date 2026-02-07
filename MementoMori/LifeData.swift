import Foundation

// MARK: - Life Data Model

struct LifeData: Codable {
    var birthDate: Date
    var lifeExpectancy: Int // in years
    
    static let defaultLifeExpectancy = 80
    
    static var `default`: LifeData {
        LifeData(
            birthDate: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
            lifeExpectancy: defaultLifeExpectancy
        )
    }
    
    // MARK: - Calculations
    
    var totalWeeks: Int {
        lifeExpectancy * 52
    }
    
    var weeksLived: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: birthDate, to: Date()).day ?? 0
        return max(0, days / 7)
    }
    
    var weeksRemaining: Int {
        max(0, totalWeeks - weeksLived)
    }
    
    var percentageLived: Double {
        guard totalWeeks > 0 else { return 0 }
        return min(1.0, Double(weeksLived) / Double(totalWeeks))
    }
    
    var currentAge: Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: birthDate, to: Date())
        return Double(components.day ?? 0) / 365.25
    }
}

// MARK: - Storage

class LifeDataStore {
    static let shared = LifeDataStore()

    static let appGroupIdentifier = "group.com.shotarok.mementomori"

    private let userDefaults: UserDefaults
    private let key = "lifeData"

    private init() {
        // Use app group for sharing between app and widget
        if let groupDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) {
            self.userDefaults = groupDefaults
        } else {
            assertionFailure("Failed to create UserDefaults for app group '\(Self.appGroupIdentifier)'. Ensure the app group is configured in both targets.")
            self.userDefaults = .standard
        }
    }

    var lifeData: LifeData {
        get {
            guard let data = userDefaults.data(forKey: key),
                  let lifeData = try? JSONDecoder().decode(LifeData.self, from: data) else {
                return .default
            }
            // Guard against corrupted data with a future birth date
            if lifeData.birthDate > Date() {
                return .default
            }
            return lifeData
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: key)
            }
        }
    }
}

// MARK: - Display Mode

enum CalendarDisplayMode: String, CaseIterable, Codable {
    case weeks = "Weeks"
    case months = "Months"
    case years = "Years"
    
    var columns: Int {
        switch self {
        case .weeks: return 52   // 52 weeks per row (1 year)
        case .months: return 12  // 12 months per row (1 year)
        case .years: return 10   // 10 years per row
        }
    }
    
    func totalUnits(for lifeExpectancy: Int) -> Int {
        switch self {
        case .weeks: return lifeExpectancy * 52
        case .months: return lifeExpectancy * 12
        case .years: return lifeExpectancy
        }
    }
    
    func unitsLived(from birthDate: Date) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .weeks:
            let days = calendar.dateComponents([.day], from: birthDate, to: now).day ?? 0
            return max(0, days / 7)
        case .months:
            let months = calendar.dateComponents([.month], from: birthDate, to: now).month ?? 0
            return max(0, months)
        case .years:
            let years = calendar.dateComponents([.year], from: birthDate, to: now).year ?? 0
            return max(0, years)
        }
    }
}
