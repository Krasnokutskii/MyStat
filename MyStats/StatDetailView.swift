import SwiftUI
import Charts // Requires iOS 16+
import SwiftData

struct StatDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let personId: UUID
    let statDefinition: StatDefinition
    @State private var newValue = ""
    
    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    
                    headerView
                        .frame(height: 100)
                        .padding(20)
                    
                    AddNewMeasurementView(statDefinition: statDefinition)
                    
                    if statDefinition.measurementType != .text && statDefinition.measurements.count > 1 {
                        VStack(alignment: .leading, spacing: 10) {
                            ChartView(measurements: statDefinition.measurements.sorted(by: { $0.date < $1.date }))
                                .frame(height: 200)
                                .padding(.vertical)
                        }
                        .padding()
                        .background(Color(UIColor.systemGroupedBackground))
                        .cornerRadius(10)
                    }
                    
                    // History Section
                    if !statDefinition.measurements.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("History")
                                .font(.headline)
                            history
                        }
                        .padding()
                        .background(Color(UIColor.systemGroupedBackground))
                        .cornerRadius(10)
                    }
                    
                    // Stats Section
                    if statDefinition.measurementType != .text && statDefinition.measurements.count > 1 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Statistics")
                                .font(.headline)
                            statistics
                        }
                        .padding()
                        .background(Color(UIColor.systemGroupedBackground))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
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
    
    private var formattedMonthAndDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d HH:mm"
        let formattedDate = formatter.string(from: Date())

        // Ensure first letter is capitalized
        return formattedDate.prefix(1).capitalized + formattedDate.dropFirst()
    }
    
    private var headerView: some View {
        ZStack {
            // Background with half-transparent blue color
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1)) // 50% transparency
                .frame(maxWidth: .infinity) // Expands width
                .padding(.horizontal) // Adds some space on the sides

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
