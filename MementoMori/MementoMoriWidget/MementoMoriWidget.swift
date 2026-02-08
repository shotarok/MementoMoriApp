import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct MementoMoriProvider: TimelineProvider {
    func placeholder(in context: Context) -> MementoMoriEntry {
        MementoMoriEntry(date: Date(), lifeData: .default)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MementoMoriEntry) -> Void) {
        let entry = MementoMoriEntry(date: Date(), lifeData: LifeDataStore.shared.lifeData)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MementoMoriEntry>) -> Void) {
        let currentDate = Date()
        let lifeData = LifeDataStore.shared.lifeData
        
        // Create entry for current state
        let entry = MementoMoriEntry(date: currentDate, lifeData: lifeData)
        
        // Refresh at the start of next calendar week (Monday)
        let calendar = Calendar.current
        let startOfNextWeek: Date = {
            var nextMonday = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)
            nextMonday.weekOfYear = (nextMonday.weekOfYear ?? 1) + 1
            nextMonday.weekday = calendar.firstWeekday
            return calendar.date(from: nextMonday) ?? calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
        }()
        
        let timeline = Timeline(entries: [entry], policy: .after(startOfNextWeek))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct MementoMoriEntry: TimelineEntry {
    let date: Date
    let lifeData: LifeData
}

// MARK: - Widget Views

struct MementoMoriWidgetEntryView: View {
    var entry: MementoMoriProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(lifeData: entry.lifeData)
        case .systemMedium:
            MediumWidgetView(lifeData: entry.lifeData)
        case .systemLarge:
            LargeWidgetView(lifeData: entry.lifeData)
        case .accessoryCircular:
            CircularAccessoryView(lifeData: entry.lifeData)
        case .accessoryRectangular:
            RectangularAccessoryView(lifeData: entry.lifeData)
        case .accessoryInline:
            InlineAccessoryView(lifeData: entry.lifeData)
        default:
            SmallWidgetView(lifeData: entry.lifeData)
        }
    }
}

// MARK: - Small Widget (Years grid)

struct SmallWidgetView: View {
    let lifeData: LifeData
    
    private var yearsLived: Int {
        CalendarDisplayMode.years.unitsLived(from: lifeData.birthDate)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Title
            Text("MEMENTO MORI")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
            
            // Years grid (10 columns x 9 rows = 90 years max display)
            let columns = 10
            let rows = min(9, (lifeData.lifeExpectancy + columns - 1) / columns)
            let totalYears = rows * columns
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: columns),
                spacing: 3
            ) {
                ForEach(0..<totalYears, id: \.self) { index in
                    if index < lifeData.lifeExpectancy {
                        Circle()
                            .fill(index < yearsLived ? Color.primary : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            // Stats
            HStack {
                Text("\(yearsLived)")
                    .font(.system(size: 11, weight: .bold))
                Text("of")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text("\(lifeData.lifeExpectancy)")
                    .font(.system(size: 11, weight: .bold))
                Text("years")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget (Weeks grid grouped by decade)

struct MediumWidgetView: View {
    let lifeData: LifeData

    private var weeksLived: Int {
        CalendarDisplayMode.weeks.unitsLived(from: lifeData.birthDate)
    }

    private var decades: Int {
        (lifeData.lifeExpectancy + 9) / 10
    }

    var body: some View {
        HStack(spacing: 12) {
            // Left: Stats
            VStack(alignment: .leading, spacing: 0) {
                Text("MEMENTO MORI")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                Text("Your life in weeks")
                    .font(.system(size: 7))
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(lifeData.percentageLived * 100))%")
                    .font(.system(size: 24, weight: .bold))
                Text("lived")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(weeksLived)")
                            .font(.system(size: 13, weight: .semibold))
                            .monospacedDigit()
                        Text("weeks lived")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(lifeData.weeksRemaining)")
                            .font(.system(size: 13, weight: .semibold))
                            .monospacedDigit()
                        Text("weeks left")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 80)

            // Right: Weeks grid — 52 columns, rows grouped by decade
            // Uses Canvas instead of thousands of SwiftUI views to stay within widget rendering limits
            Canvas { context, size in
                let columns = 52
                let yearsPerDecade = 10
                let decadeCount = decades
                let totalYears = lifeData.lifeExpectancy
                let decadeSpacing: CGFloat = 2
                let cellSpacing: CGFloat = 0.5

                let cellWidth = max(0.5, (size.width - CGFloat(columns - 1) * cellSpacing) / CGFloat(columns))
                let extraDecadeGaps = CGFloat(max(0, decadeCount - 1)) * (decadeSpacing - cellSpacing)
                let innerSpacing = CGFloat(max(0, totalYears - 1)) * cellSpacing
                let cellHeight = max(0.5, (size.height - innerSpacing - extraDecadeGaps) / CGFloat(max(1, totalYears)))

                let livedShading: GraphicsContext.Shading = .color(.primary)
                let unlivedShading: GraphicsContext.Shading = .color(Color(.systemGray5))

                var yOffset: CGFloat = 0

                for decade in 0..<decadeCount {
                    let yearsInDecade = min(yearsPerDecade, totalYears - decade * yearsPerDecade)

                    for yearInDecade in 0..<yearsInDecade {
                        let year = decade * yearsPerDecade + yearInDecade

                        for week in 0..<columns {
                            let index = year * columns + week
                            let x = CGFloat(week) * (cellWidth + cellSpacing)
                            let rect = CGRect(x: x, y: yOffset, width: cellWidth, height: cellHeight)
                            context.fill(Path(rect), with: index < weeksLived ? livedShading : unlivedShading)
                        }

                        yOffset += cellHeight + cellSpacing
                    }

                    if decade < decadeCount - 1 {
                        yOffset += decadeSpacing - cellSpacing
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Large Widget (Full weeks grid)

struct LargeWidgetView: View {
    let lifeData: LifeData

    private var weeksLived: Int {
        CalendarDisplayMode.weeks.unitsLived(from: lifeData.birthDate)
    }

    private var decades: Int {
        (lifeData.lifeExpectancy + 9) / 10
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MEMENTO MORI")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("Your life in weeks")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(lifeData.percentageLived * 100))%")
                        .font(.system(size: 16, weight: .bold))
                    Text("\(weeksLived) / \(lifeData.totalWeeks) weeks")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }

            // Weeks grid (52 columns, rows grouped by decade)
            // Uses Canvas instead of thousands of SwiftUI views to stay within widget rendering limits
            Canvas { context, size in
                let columns = 52
                let totalYears = lifeData.lifeExpectancy
                let decadeCount = decades
                let decadeSpacing: CGFloat = 3
                let cellSpacing: CGFloat = 0.5

                // Size width and height independently so the grid fills the entire canvas
                let cellWidth = max(0.5, (size.width - CGFloat(columns - 1) * cellSpacing) / CGFloat(columns))
                let extraDecadeGaps = CGFloat(max(0, decadeCount - 1)) * (decadeSpacing - cellSpacing)
                let innerSpacing = CGFloat(max(0, totalYears - 1)) * cellSpacing
                let cellHeight = max(0.5, (size.height - innerSpacing - extraDecadeGaps) / CGFloat(max(1, totalYears)))

                let livedShading: GraphicsContext.Shading = .color(.primary)
                let unlivedShading: GraphicsContext.Shading = .color(Color(.systemGray5))

                var yOffset: CGFloat = 0

                for decade in 0..<decadeCount {
                    let yearsInDecade = min(10, totalYears - decade * 10)

                    for yearInDecade in 0..<yearsInDecade {
                        let year = decade * 10 + yearInDecade

                        for week in 0..<columns {
                            let index = year * columns + week
                            let x = CGFloat(week) * (cellWidth + cellSpacing)
                            let rect = CGRect(x: x, y: yOffset, width: cellWidth, height: cellHeight)
                            context.fill(Path(rect), with: index < weeksLived ? livedShading : unlivedShading)
                        }

                        yOffset += cellHeight + cellSpacing
                    }

                    if decade < decadeCount - 1 {
                        yOffset += decadeSpacing - cellSpacing
                    }
                }
            }

            // Footer stats
            HStack(spacing: 24) {
                statItem(value: "\(Int(lifeData.currentAge))", label: "Age")
                statItem(value: "\(weeksLived)", label: "Weeks Lived")
                statItem(value: "\(lifeData.weeksRemaining)", label: "Weeks Left")
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .monospacedDigit()
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Lock Screen Widgets

struct CircularAccessoryView: View {
    let lifeData: LifeData
    
    var body: some View {
        Gauge(value: lifeData.percentageLived) {
            Text("⏳")
        } currentValueLabel: {
            Text("\(Int(lifeData.currentAge))")
                .font(.system(size: 16, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct RectangularAccessoryView: View {
    let lifeData: LifeData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Memento Mori")
                .font(.system(size: 12, weight: .semibold))
            
            Gauge(value: lifeData.percentageLived) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinear)
            
            Text("\(lifeData.weeksRemaining) weeks remaining")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}

struct InlineAccessoryView: View {
    let lifeData: LifeData
    
    var body: some View {
        Text("⏳ \(lifeData.weeksRemaining) weeks left")
    }
}

// MARK: - Widget Configuration

struct MementoMoriWidget: Widget {
    let kind: String = "MementoMoriWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MementoMoriProvider()) { entry in
            MementoMoriWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Memento Mori")
        .description("Remember that you will die. View your life in weeks, months, or years.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    MementoMoriWidget()
} timeline: {
    MementoMoriEntry(date: Date(), lifeData: .default)
}

#Preview("Medium", as: .systemMedium) {
    MementoMoriWidget()
} timeline: {
    MementoMoriEntry(date: Date(), lifeData: .default)
}

#Preview("Large", as: .systemLarge) {
    MementoMoriWidget()
} timeline: {
    MementoMoriEntry(date: Date(), lifeData: .default)
}
