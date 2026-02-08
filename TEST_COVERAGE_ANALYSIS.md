# Test Coverage Analysis — MementoMoriApp

## Current State

The project has **zero test coverage**. There are no unit tests, integration tests, UI tests, or snapshot tests. No test targets exist in the Xcode project, and no CI pipeline is configured.

The codebase consists of 5 Swift source files across 2 targets (main app + widget extension). Despite the small size, there is meaningful logic that should be tested.

---

## Proposed Test Areas (Priority Order)

### 1. `LifeData` Model Calculations (High Priority)

**File:** `MementoMori/LifeData.swift:5-44`

The `LifeData` struct contains the core business logic of the app. All computed properties derive from `birthDate` and `lifeExpectancy`, making them highly testable pure functions (when injecting a reference date).

| Property | What to test |
|---|---|
| `totalWeeks` | Returns `lifeExpectancy * 52` for various values |
| `weeksLived` | Correct week count for known birth dates |
| `weeksRemaining` | `totalWeeks - weeksLived`, never negative |
| `percentageLived` | Returns 0..1 range; handles `totalWeeks == 0`; clamps at 1.0 |
| `currentAge` | Correct fractional age for known dates |

**Recommended test cases:**
- Standard case: 30-year-old with 80-year expectancy
- Edge case: birth date is today (newborn) — all "lived" values should be 0
- Edge case: age exceeds life expectancy — `weeksRemaining` should be 0, `percentageLived` clamped to 1.0
- Edge case: `lifeExpectancy` of 0 — `percentageLived` should return 0 (division guard)
- Boundary: birth date exactly on a week boundary vs. mid-week

**Design note:** The current computed properties call `Date()` internally, making them non-deterministic. To test properly, refactor the calculations to accept a `referenceDate: Date` parameter (defaulting to `Date()`), or extract the math into standalone functions. This is the single most impactful refactor for testability.

---

### 2. `CalendarDisplayMode` Logic (High Priority)

**File:** `MementoMori/LifeData.swift:88-125`

The enum has three computed/function members with branching logic per case.

| Member | What to test |
|---|---|
| `columns` | 52 for weeks, 12 for months, 10 for years |
| `totalUnits(for:)` | Correct multiplication for each mode |
| `unitsLived(from:)` | Correct date arithmetic for weeks, months, and years |

**Recommended test cases:**
- All three modes with a known birth date and reference date
- `unitsLived` with a future birth date (should return 0 due to `max(0, ...)`)
- `unitsLived` at exact year/month/week boundaries

---

### 3. `LifeDataStore` Persistence (Medium Priority)

**File:** `MementoMori/LifeData.swift:48-84`

The store handles encoding/decoding and has a guard against corrupted data.

| Scenario | What to test |
|---|---|
| Round-trip | Save `LifeData`, read it back, verify equality |
| Missing data | When no key exists, returns `.default` |
| Corrupted data | When stored data isn't valid JSON, returns `.default` |
| Future birth date guard | When stored `birthDate > Date()`, returns `.default` |
| Encoding failure | Verify behavior when encode/decode fails |

**Design note:** The singleton pattern and private initializer make this hard to test. Refactor by:
- Accepting a `UserDefaults` instance via initializer injection instead of creating it internally
- Making `init` internal (or at least `init(userDefaults:)` available for tests)
- This allows tests to pass `UserDefaults(suiteName: "test-suite")` and clean up between runs

---

### 4. Widget Timeline Provider (Medium Priority)

**File:** `MementoMori/MementoMoriWidget/MementoMoriWidget.swift:6-35`

`MementoMoriProvider` builds timelines that control when the widget refreshes.

| Scenario | What to test |
|---|---|
| `placeholder(in:)` | Returns entry with `.default` life data |
| `getSnapshot(in:completion:)` | Returns entry with current store data |
| `getTimeline(in:completion:)` | Returns exactly 1 entry; refresh policy is `.after(startOfNextWeek)` |
| Next-week calculation | The `startOfNextWeek` closure computes the correct next Monday |

**Design note:** The provider reads from `LifeDataStore.shared` directly, making it coupled to the singleton. Injecting a data source protocol would improve testability.

---

### 5. `LifeData` Codable Conformance (Low Priority)

**File:** `MementoMori/LifeData.swift:5`

Since the app persists `LifeData` as JSON, round-trip encoding/decoding correctness matters.

| Scenario | What to test |
|---|---|
| Encode then decode | `LifeData` survives a JSON round-trip with identical values |
| Decode from known JSON | A hardcoded JSON string decodes to expected values |
| Schema evolution | If fields are added/removed in the future, old JSON still decodes (forward compatibility) |

---

### 6. UI / Snapshot Tests (Low Priority)

**Files:** `ContentView.swift`, `MementoMoriWidget.swift`

SwiftUI views are harder to unit-test but can benefit from snapshot testing.

| Area | What to test |
|---|---|
| `MementoMoriCalendarView` | Renders correct number of dots for each display mode |
| Widget views (Small/Medium/Large) | Snapshot tests to catch layout regressions |
| Lock screen widgets | Snapshot tests for accessory views |
| `ContentView` settings | Birth date picker range doesn't allow future dates |

**Tooling:** Consider a library like [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) for view regression tests.

---

## Refactoring Recommendations for Testability

### A. Make date calculations deterministic

Currently, `weeksLived`, `currentAge`, and `unitsLived(from:)` all call `Date()` internally. This makes tests flaky and time-dependent.

**Proposed fix:** Add a `referenceDate` parameter:

```swift
func weeksLived(asOf referenceDate: Date = Date()) -> Int {
    let days = Calendar.current.dateComponents([.day], from: birthDate, to: referenceDate).day ?? 0
    return max(0, days / 7)
}
```

This is a non-breaking change (the default parameter preserves existing call sites) and unlocks fully deterministic tests.

### B. Make `LifeDataStore` injectable

Replace the private singleton init with dependency injection:

```swift
class LifeDataStore {
    static let shared = LifeDataStore()

    private let userDefaults: UserDefaults
    private let key = "lifeData"

    init(userDefaults: UserDefaults? = nil) {
        self.userDefaults = userDefaults
            ?? UserDefaults(suiteName: Self.appGroupIdentifier)
            ?? .standard
    }
}
```

Tests can then create isolated instances with a test-specific `UserDefaults` suite.

### C. Extract a data source protocol for the widget

```swift
protocol LifeDataProviding {
    var lifeData: LifeData { get }
}
```

This lets the widget provider be tested with mock data sources.

---

## Suggested Testing Stack

| Tool | Purpose |
|---|---|
| **XCTest** | Unit tests for models, calculations, persistence |
| **swift-snapshot-testing** | Visual regression tests for SwiftUI views and widgets |
| **Xcode Test Plans** | Organize tests by target (unit vs. UI) |
| **GitHub Actions** | CI pipeline to run tests on every push (`xcodebuild test`) |

---

## Summary Table

| Area | Priority | Test Count Estimate | Requires Refactoring? |
|---|---|---|---|
| `LifeData` calculations | High | ~15 tests | Yes (add `referenceDate`) |
| `CalendarDisplayMode` | High | ~10 tests | Yes (add `referenceDate`) |
| `LifeDataStore` persistence | Medium | ~8 tests | Yes (DI for UserDefaults) |
| Widget timeline provider | Medium | ~5 tests | Yes (DI for data source) |
| Codable round-trip | Low | ~3 tests | No |
| UI / snapshot tests | Low | ~6 tests | No |
| **Total** | | **~47 tests** | |

Starting with the high-priority `LifeData` and `CalendarDisplayMode` tests would cover the core logic with the best effort-to-value ratio. The refactoring needed (adding `referenceDate` parameters) is minimal and non-breaking.
