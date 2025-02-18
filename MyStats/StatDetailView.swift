import SwiftUI
import Charts // Requires iOS 16+
import SwiftData

struct StatDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let personId: UUID
    let statDefinition: StatDefinition
    @State private var showingAddMeasurement = false
    @State private var newValue = ""
    @State private var selectedDate = Date()
    
    var body: some View {
        List {
            // Header Section
            Section {
                VStack(spacing: 16) {
                    Image(systemName: statDefinition.systemImage)
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text(statDefinition.name)
                        .font(.title)
                        .bold()
                    
                    if let lastMeasurement = statDefinition.measurements.last {
                        HStack(spacing: 4) {
                            Text("Current:")
                                .foregroundColor(.secondary)
                            Text(formatValue(lastMeasurement))
                                .font(.title2)
                                .bold()
                                .foregroundColor(.primary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            // Chart Section
            if statDefinition.measurementType != .text && statDefinition.measurements.count > 1 {
                Section {
                    ChartView(measurements: statDefinition.measurements.sorted(by: { $0.date < $1.date }))
                        .frame(height: 200)
                        .padding(.vertical)
                }
            }
            
            // Add New Measurement Section
            Section {
                VStack(spacing: 12) {
                    HStack {
                        TextField("New Value", text: $newValue)
                            .keyboardType(statDefinition.measurementType == .text ? .default : .decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if statDefinition.measurementType != .text {
                            Stepper("", value: Binding(
                                get: { Double(newValue) ?? 0 },
                                set: { newValue = String(format: "%.1f", $0) }
                            ),
                                   step: statDefinition.step)
                        }
                    }
                    
                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                    
                    Button(action: addMeasurement) {
                        Text("Add Measurement")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(newValue.isEmpty)
                }
                .padding(.vertical, 8)
            }
            
            // History Section
            if !statDefinition.measurements.isEmpty {
                Section(header: Text("History")) {
                    ForEach(statDefinition.measurements.sorted(by: { $0.date > $1.date })) { measurement in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(formatValue(measurement))
                                    .font(.headline)
                                Text(formatDate(measurement.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if let previousMeasurement = getPreviousMeasurement(for: measurement),
                               statDefinition.measurementType != .text {
                                let difference = measurement.value - previousMeasurement.value
                                Text(formatDifference(difference))
                                    .font(.caption)
                                    .foregroundColor(difference >= 0 ? .green : .red)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteMeasurement(measurement)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            // Stats Section
            if statDefinition.measurementType != .text && statDefinition.measurements.count > 1 {
                Section(header: Text("Statistics")) {
                    StatRow(title: "Average", value: calculateAverage())
                    StatRow(title: "Minimum", value: calculateMin())
                    StatRow(title: "Maximum", value: calculateMax())
                    if let trend = calculateTrend() {
                        StatRow(title: "Trend", value: trend, showTrend: true)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatValue(_ measurement: StatMeasurement) -> String {
        if statDefinition.measurementType == .text {
            return measurement.textValue ?? ""
        } else {
            return String(format: "%.1f", measurement.value)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDifference(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.1f", value))"
    }
    
    private func getPreviousMeasurement(for measurement: StatMeasurement) -> StatMeasurement? {
        let sortedMeasurements = statDefinition.measurements.sorted(by: { $0.date > $1.date })
        guard let index = sortedMeasurements.firstIndex(where: { $0.id == measurement.id }),
              index < sortedMeasurements.count - 1 else {
            return nil
        }
        return sortedMeasurements[index + 1]
    }
    
    private func addMeasurement() {
        let measurement = StatMeasurement(
            date: selectedDate, value: Double(newValue) ?? 0,
            textValue: statDefinition.measurementType == .text ? newValue : nil
        )
        statDefinition.measurements.append(measurement)
        newValue = ""
        selectedDate = Date()
    }
    
    private func deleteMeasurement(_ measurement: StatMeasurement) {
        if let index = statDefinition.measurements.firstIndex(where: { $0.id == measurement.id }) {
            statDefinition.measurements.remove(at: index)
        }
    }
    
    private func calculateAverage() -> Double {
        let values = statDefinition.measurements.map { $0.value }
        return values.reduce(0, +) / Double(values.count)
    }
    
    private func calculateMin() -> Double {
        statDefinition.measurements.map { $0.value }.min() ?? 0
    }
    
    private func calculateMax() -> Double {
        statDefinition.measurements.map { $0.value }.max() ?? 0
    }
    
    private func calculateTrend() -> Double? {
        guard statDefinition.measurements.count >= 2 else { return nil }
        let sortedMeasurements = statDefinition.measurements.sorted(by: { $0.date < $1.date })
        let first = sortedMeasurements.first!.value
        let last = sortedMeasurements.last!.value
        return last - first
    }
}

struct StatRow: View {
    let title: String
    let value: Double
    var showTrend = false
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if showTrend {
                Text(String(format: "%.1f", value))
                    .foregroundColor(value >= 0 ? .green : .red)
            } else {
                Text(String(format: "%.1f", value))
            }
        }
    }
}

struct ChartView: View {
    let measurements: [StatMeasurement]
    @State private var selectedMeasurement: StatMeasurement?
    
    private var sortedMeasurements: [StatMeasurement] {
        measurements.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        mainChart
            .chartXScale(domain: chartDomain)
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis(content: xAxis)
            .chartYAxis(content: yAxis)
            .frame(height: 220)
            .padding(.vertical)
            .gesture(selectionGesture)
    }
    
    private var mainChart: some View {
        Chart(sortedMeasurements) { measurement in
            areaMark(for: measurement)
            lineMark(for: measurement)
            dotMark(for: measurement)
            selectionMark(for: measurement)
        }
    }
    
    private func areaMark(for measurement: StatMeasurement) -> some ChartContent {
        AreaMark(
            x: .value("Date", measurement.date),
            y: .value("Value", measurement.value)
        )
        .foregroundStyle(
            LinearGradient(
                colors: [
                    .orange.opacity(0.3),
                    .orange.opacity(0.1),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .interpolationMethod(.cardinal)
    }
    
    private func lineMark(for measurement: StatMeasurement) -> some ChartContent {
        LineMark(
            x: .value("Date", measurement.date),
            y: .value("Value", measurement.value)
        )
        .interpolationMethod(.cardinal)
        .foregroundStyle(.orange)
        .lineStyle(StrokeStyle(lineWidth: 2))
    }
    
    private func dotMark(for measurement: StatMeasurement) -> some ChartContent {
        PointMark(
            x: .value("Date", measurement.date),
            y: .value("Value", measurement.value)
        )
        .foregroundStyle(selectedMeasurement?.id == measurement.id ? .orange : .white)
        //.stroke(.orange, lineWidth: selectedMeasurement?.id == measurement.id ? 4 : 2)
        .symbolSize(selectedMeasurement?.id == measurement.id ? 150 : 100)
    }
    
    private func selectionMark(for measurement: StatMeasurement) -> some ChartContent {
        if selectedMeasurement?.id == measurement.id {
            return RuleMark(
                x: .value("Date", measurement.date)
            )
            .foregroundStyle(.secondary.opacity(0.3))
            .annotation(position: .top) {
                selectionAnnotation(for: measurement)
            }
        } else {
            return RuleMark(
                x: .value("Date", measurement.date)
            )
            .opacity(0)
        }
    }
    
    private func selectionAnnotation(for measurement: StatMeasurement) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(format: "%.1f", measurement.value))
                .font(.headline)
                .foregroundColor(.orange)
            Text(measurement.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.background)
                .shadow(radius: 2)
        )
    }
    
    private var chartDomain: ClosedRange<Date> {
        let startDate = sortedMeasurements.first?.date ?? Date()
        let endDate = sortedMeasurements.last?.date ?? Date()
        return startDate...endDate
    }
    
    private func xAxis() -> some AxisContent {
        AxisMarks(position: .bottom) { value in
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(date.formatted(.dateTime.month().day()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func yAxis() -> some AxisContent {
        AxisMarks { value in
            AxisValueLabel {
                if let number = value.as(Double.self) {
                    Text(String(format: "%.1f", number))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var selectionGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                updateSelection(at: value.location)
            }
            .onEnded { _ in
                selectedMeasurement = nil
            }
    }
    
    private func updateSelection(at location: CGPoint) {
        guard let closestMeasurement = sortedMeasurements.min(by: {
            abs($0.date.timeIntervalSince1970 - Double(location.x)) <
            abs($1.date.timeIntervalSince1970 - Double(location.x))
        }) else { return }
        
        selectedMeasurement = closestMeasurement
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Person.self, StatDefinition.self, StatCategory.self, StatMeasurement.self, configurations: config)
        
        return NavigationStack {
            StatDetailView(
                personId: UUID(),
                statDefinition: StatDefinition(
                    name: "Example Stat",
                    measurementType: .decimal,
                    step: 0.5,
                    initialValue: "0",
                    systemImage: "ruler.fill",
                    categoryId: UUID()
                )
            )
            .modelContainer(container)
        }
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
} 
