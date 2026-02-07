import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var birthDate: Date = LifeDataStore.shared.lifeData.birthDate
    @State private var lifeExpectancy: Int = LifeDataStore.shared.lifeData.lifeExpectancy
    @State private var displayMode: CalendarDisplayMode = .years
    
    private var lifeData: LifeData {
        LifeData(birthDate: birthDate, lifeExpectancy: lifeExpectancy)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats Card
                    statsCard
                    
                    // Calendar Preview
                    calendarPreview
                    
                    // Settings
                    settingsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Memento Mori")
        }
    }
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        VStack(spacing: 16) {
            Text("Memento mori.")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 32) {
                statItem(value: "\(Int(lifeData.currentAge))", label: "Years Old")
                statItem(value: "\(lifeData.weeksLived)", label: "Weeks Lived")
                statItem(value: "\(lifeData.weeksRemaining)", label: "Weeks Left")
            }
            
            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary)
                            .frame(width: geometry.size.width * lifeData.percentageLived)
                    }
                }
                .frame(height: 8)
                
                Text("\(Int(lifeData.percentageLived * 100))% of your life")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Calendar Preview
    
    private var calendarPreview: some View {
        VStack(spacing: 12) {
            // Mode Picker
            Picker("Display", selection: $displayMode) {
                ForEach(CalendarDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            // Calendar Grid
            let dotSize: CGFloat = displayMode == .weeks ? 3 : (displayMode == .months ? 6 : 10)
            let spacing: CGFloat = displayMode == .weeks ? 1 : 2
            let totalUnits = displayMode.totalUnits(for: lifeExpectancy)
            let columns = displayMode.columns
            let rows = (totalUnits + columns - 1) / columns
            let calendarHeight = CGFloat(rows) * (dotSize + spacing) - spacing

            MementoMoriCalendarView(
                lifeData: lifeData,
                displayMode: displayMode,
                dotSize: dotSize,
                spacing: spacing
            )
            .frame(height: calendarHeight)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Settings
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Birth Date
                DatePicker(
                    "Birth Date",
                    selection: $birthDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .onChange(of: birthDate) { _, newValue in
                    saveData()
                }
                
                Divider()
                
                // Life Expectancy
                HStack {
                    Text("Life Expectancy")
                    Spacer()
                    Stepper("\(lifeExpectancy) years", value: $lifeExpectancy, in: 50...120)
                        .onChange(of: lifeExpectancy) { _, newValue in
                            saveData()
                        }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            Text("Add the Memento Mori widget to your home screen to see your life calendar at a glance.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    
    private func saveData() {
        LifeDataStore.shared.lifeData = lifeData
        // Refresh widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Calendar View

struct MementoMoriCalendarView: View {
    let lifeData: LifeData
    let displayMode: CalendarDisplayMode
    var dotSize: CGFloat = 6
    var spacing: CGFloat = 2
    private var totalUnits: Int {
        displayMode.totalUnits(for: lifeData.lifeExpectancy)
    }
    
    private var unitsLived: Int {
        displayMode.unitsLived(from: lifeData.birthDate)
    }
    
    private var columns: Int {
        displayMode.columns
    }
    
    private var rows: Int {
        (totalUnits + columns - 1) / columns
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let calculatedDotSize = (availableWidth - (spacing * CGFloat(columns - 1))) / CGFloat(columns)
            let actualDotSize = min(dotSize, calculatedDotSize)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(actualDotSize), spacing: spacing), count: columns),
                spacing: spacing
            ) {
                ForEach(0..<totalUnits, id: \.self) { index in
                    Circle()
                        .fill(index < unitsLived ? Color.primary : Color(.systemGray4))
                        .frame(width: actualDotSize, height: actualDotSize)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
