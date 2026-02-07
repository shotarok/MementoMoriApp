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
        HStack(spacing: 16) {
            // Left: Stats
            VStack(alignment: .leading, spacing: 4) {
                Text("MEMENTO MORI")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                Text("Your life in weeks")
                    .font(.system(size: 7))
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(lifeData.percentageLived * 100))%")
                    .font(.system(size: 22, weight: .bold))
                Text("lived")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(weeksLived)")
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
                Text("weeks lived")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(lifeData.weeksRemaining)")
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
                Text("weeks left")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .frame(width: 76)

            // Right: Weeks grid — 52 columns, 80 rows grouped by decade
            GeometryReader { geometry in
                let columns = 52
                let yearsPerDecade = 10
                let decadeCount = decades
                let totalYears = lifeData.lifeExpectancy
                let decadeSpacing: CGFloat = 2
                let cellSpacing: CGFloat = 0.5
                let availableHeight = geometry.size.height - (CGFloat(decadeCount - 1) * decadeSpacing)
                let totalCellRows = totalYears
                let totalInnerSpacing = CGFloat(totalCellRows - decadeCount) * cellSpacing
                let cellHeight = (availableHeight - totalInnerSpacing) / CGFloat(totalCellRows)
                let cellWidth = (geometry.size.width - (CGFloat(columns - 1) * cellSpacing)) / CGFloat(columns)

                VStack(spacing: decadeSpacing) {
                    ForEach(0..<decadeCount, id: \.self) { decade in
                        let yearsInDecade = min(yearsPerDecade, totalYears - decade * yearsPerDecade)

                        VStack(spacing: cellSpacing) {
                            ForEach(0..<yearsInDecade, id: \.self) { yearInDecade in
                                let year = decade * yearsPerDecade + yearInDecade
                                HStack(spacing: cellSpacing) {
                                    ForEach(0..<columns, id: \.self) { week in
                                        let index = year * columns + week
                                        Rectangle()
                                            .fill(index < weeksLived ? Color.primary : Color(.systemGray5))
                                            .frame(width: cellWidth, height: cellHeight)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Large Widget (Full weeks grid)

struct LargeWidgetView: View {
    let lifeData: LifeData
    
    private var weeksLived: Int {
        CalendarDisplayMode.weeks.unitsLived(from: lifeData.birthDate)
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
            
            // Weeks grid (52 columns = 1 year per row)
            let columns = 52
            let rows = lifeData.lifeExpectancy
            let totalWeeks = rows * columns
            
            GeometryReader { geometry in
                let spacing: CGFloat = 0.5
                let widthBasedSize = (geometry.size.width - (CGFloat(columns - 1) * spacing)) / CGFloat(columns)
                let heightBasedSize = (geometry.size.height - (CGFloat(rows - 1) * spacing)) / CGFloat(rows)
                let dotSize = min(widthBasedSize, heightBasedSize)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(dotSize), spacing: spacing), count: columns),
                    spacing: spacing
                ) {
                    ForEach(0..<totalWeeks, id: \.self) { index in
                        Rectangle()
                            .fill(index < weeksLived ? Color.primary : Color(.systemGray5))
                            .frame(width: dotSize, height: dotSize)
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
