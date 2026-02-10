import Testing
import Foundation
@testable import MementoMori

struct LifeDataTests {
    private static let calendar = Calendar.current

    private static func date(daysAgo days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: Date())!
    }

    // MARK: - totalDays

    @Test(arguments: zip(
        [80,    50,    100,   120],
        [29220, 18262, 36525, 43830]
    ))
    func totalDays(lifeExpectancy: Int, expected: Int) {
        let data = LifeData(birthDate: Date(), lifeExpectancy: lifeExpectancy)
        #expect(data.totalDays == expected)
    }

    // MARK: - Day-based progress

    struct ProgressCase: CustomTestStringConvertible, Sendable {
        let testDescription: String
        let daysAgo: Int
        let lifeExpectancy: Int
        let expectedDaysLived: Int
        let expectedDaysRemaining: Int
        let expectedPercentage: Double

        static let all: [ProgressCase] = [
            ProgressCase(
                testDescription: "Newborn (0 days, 80y)",
                daysAgo: 0,
                lifeExpectancy: 80,
                expectedDaysLived: 0,
                expectedDaysRemaining: 29220,
                expectedPercentage: 0.0
            ),
            ProgressCase(
                testDescription: "1 year old (365 days, 80y)",
                daysAgo: 365,
                lifeExpectancy: 80,
                expectedDaysLived: 365,
                expectedDaysRemaining: 28855,
                expectedPercentage: 365.0 / 29220.0
            ),
            ProgressCase(
                testDescription: "Quarter life (25%, 80y)",
                daysAgo: 7305,
                lifeExpectancy: 80,
                expectedDaysLived: 7305,
                expectedDaysRemaining: 21915,
                expectedPercentage: 0.25
            ),
            ProgressCase(
                testDescription: "Half life (50%, 80y)",
                daysAgo: 14610,
                lifeExpectancy: 80,
                expectedDaysLived: 14610,
                expectedDaysRemaining: 14610,
                expectedPercentage: 0.5
            ),
            ProgressCase(
                testDescription: "At life expectancy (80y)",
                daysAgo: 29220,
                lifeExpectancy: 80,
                expectedDaysLived: 29220,
                expectedDaysRemaining: 0,
                expectedPercentage: 1.0
            ),
            ProgressCase(
                testDescription: "Past life expectancy (capped at 100%)",
                daysAgo: 35000,
                lifeExpectancy: 80,
                expectedDaysLived: 35000,
                expectedDaysRemaining: 0,
                expectedPercentage: 1.0
            ),
            ProgressCase(
                testDescription: "10 years into 50y expectancy",
                daysAgo: 3653,
                lifeExpectancy: 50,
                expectedDaysLived: 3653,
                expectedDaysRemaining: 14609,
                expectedPercentage: 3653.0 / 18262.0
            ),
        ]
    }

    @Test(arguments: ProgressCase.all)
    func dayProgress(_ testCase: ProgressCase) {
        let data = LifeData(
            birthDate: Self.date(daysAgo: testCase.daysAgo),
            lifeExpectancy: testCase.lifeExpectancy
        )
        #expect(data.daysLived == testCase.expectedDaysLived)
        #expect(data.daysRemaining == testCase.expectedDaysRemaining)
        #expect(abs(data.percentageLived - testCase.expectedPercentage) < 1e-10)
    }

    // MARK: - Edge case: zero life expectancy

    @Test
    func zeroLifeExpectancy() {
        let data = LifeData(birthDate: Self.date(daysAgo: 100), lifeExpectancy: 0)
        #expect(data.totalDays == 0)
        #expect(data.percentageLived == 0.0)
        #expect(data.daysRemaining == 0)
    }

    // MARK: - formattedPercentageLived

    @Test(arguments: zip(
        [0,    1,     2,      3,       4,        5],
        ["50", "50.0", "50.00", "50.000", "50.0000", "50.00000"]
    ))
    func formattedPercentageLived(decimalPlaces: Int, expected: String) {
        // 14610 days = exactly 50% of 29220 total days (80-year expectancy)
        let data = LifeData(
            birthDate: Self.date(daysAgo: 14610),
            lifeExpectancy: 80,
            decimalPlaces: decimalPlaces
        )
        #expect(data.formattedPercentageLived == expected)
    }
}
