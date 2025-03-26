import SwiftUI
import Charts // Requires iOS 16+
import SwiftData

struct StatDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) var editMode
    let personId: UUID
    let statDefinition: StatDefinition
    @State private var newValue = ""
    @State private var selectedDate = Date()
    
    var body: some View {
        List {
            Section {
                headerView
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
                addNewMeasurement
            }
            
            // History Section
            if !statDefinition.measurements.isEmpty {
                Section(header: Text("History")) {
                    history
                }
            }
            
            // Stats Section
            if statDefinition.measurementType != .text && statDefinition.measurements.count > 1 {
                Section(header: Text("Statistics")) {
                    statistics
                }
            }
        }
        .toolbar {
            if editMode?.wrappedValue == .active {
                EditButton()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var statistics: some View {
        StatRow(title: "Average", value: calculateAverage())
        StatRow(title: "Minimum", value: calculateMin())
        StatRow(title: "Maximum", value: calculateMax())
        if let trend = calculateTrend() {
            StatRow(title: "Trend", value: trend, showTrend: true)
        }
    }
    
    private var history: some View {
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
    
    private var addNewMeasurement: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("New Value", text: $newValue)
                    .keyboardType(statDefinition.measurementType == .text ? .default : .decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            if editMode?.wrappedValue == .inactive {
                HStack {
                    Text(Date.now.formatted())
                    Spacer()
                    Button("Edit") {
                        editMode?.wrappedValue = .active
                    }
                }
                .padding(8)
            } else {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
            }
            
            if statDefinition.measurementType == .text {
                // Single button for text measurements
                Button(action: setMeasurement) {
                    Text("Set Value")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(newValue.isEmpty)
            } else {
                // Two buttons for numeric measurements
                HStack(spacing: 12) {
                    Button(action: setMeasurement) {
                        Text("Set Value")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(newValue.isEmpty)
                }
            }
        }
        .padding(.vertical, 8)
    }
    private var headerView: some View {
            VStack(spacing: 16) {
                Image(systemName: statDefinition.systemImage)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text(statDefinition.name)
                    .font(.title)
                    .bold()
                
                if let lastMeasurement = statDefinition.measurements.lastByDate() {
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
    
    private func setMeasurement() {
        let date = selectedDate
        let measurement = StatMeasurement(
            date: date,
            value: Double(newValue) ?? 0,
            textValue: statDefinition.measurementType == .text ? newValue : nil
        )
        statDefinition.measurements.append(measurement)
        newValue = ""
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

#Preview {
    StatDetailView(personId: UUID(), statDefinition: StatDefinition(id:UUID(), name: "Name", measurementType: MeasurementType.decimal, systemImage:"ruler.fill", categoryId: UUID()) )
}
