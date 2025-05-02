import SwiftUI
import Charts // Requires iOS 16+
import SwiftData

struct StatDetailView: View {
    let person: Person
    let statDefinition: StatDefinition
    @State private var newValue = ""
    
    var body: some View {
        VStack{
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    
                    headerView
                        .padding(20)
                    
                    if statDefinition.measurementType != .text && statDefinition.measurements.count > 1 {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                                .frame(maxWidth: .infinity)
                            VStack(alignment: .leading, spacing: 10) {
                                ChartView(measurements: statDefinition.measurements)
                                    .frame(height: 200)
                                    .padding(.vertical)
                            }
                            .padding()
                        }
                    }
                    
                    // History Section
                    if !statDefinition.measurements.isEmpty {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                                .frame(maxWidth: .infinity)
                            VStack(alignment: .leading, spacing: 10) {
                                Text("History")
                                    .font(.headline)
                                history
                            }
                            .padding()
                        }
                    }
                    
                    // Stats Section
                    if statDefinition.measurementType != .text && statDefinition.measurements.count > 1 {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                                .frame(maxWidth: .infinity)
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Statistics")
                                    .font(.headline)
                                statistics
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }
            AddNewMeasurementView(statDefinition: statDefinition)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color.blue.opacity(0.1)))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.bottom, 16)
        }
    }
    
    @ViewBuilder
    private var statistics: some View {
        if let avarage = calculateAverage() {
            StatRow(title: "Average", value: avarage)
        }
        if let minimim = calculateMin(), let maximim = calculateMax() {
            StatRow(title: "Minimum", value: minimim)
            StatRow(title: "Maximum", value: maximim)
        }
        if let trend = calculateTrend() {
            StatRow(title: "Trend", value: trend, showTrend: true)
        }
    }
    
    @State private var showAllMeasurements = false
    
    private var history: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(displayedMeasurements) { statMeasurement in
                HStack {
                    VStack(alignment: .leading) {
                        Text(formatValue(statMeasurement))
                            .font(.headline)
                        Text(formatDate(statMeasurement.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let previousMeasurement = getPreviousMeasurement(for: statMeasurement),
                       statDefinition.measurementType != .text,
                       let currentValue = Double(statMeasurement.value),
                       let previousValue = Double(previousMeasurement.value) {
                        
                        let difference = currentValue - previousValue
                        Text(formatDifference(difference))
                            .font(.caption)
                            .foregroundColor(difference >= 0 ? .green : .red)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteMeasurement(statMeasurement)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            
            // Expand/Collapse Button
            if statDefinition.measurements.count > 5 {
                Button(action: {
                    withAnimation {
                        showAllMeasurements.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: showAllMeasurements ? "chevron.up" : "chevron.down")
                        Text(showAllMeasurements ? "Collapse" : "Expand")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                }
            }
        }
    }
    
    // Computed property to control displayed measurements
    private var displayedMeasurements: [StatMeasurement] {
        let measurements = statDefinition.sortedMeasurements
        return showAllMeasurements ? measurements : Array(measurements.prefix(5))
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
        return "\(measurement.value)"
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
    
    private func calculateAverage() -> Double? {
        guard statDefinition.measurementType != .text else { return nil }
        let values = statDefinition.measurements
            .compactMap { Double($0.value)}
        
        return values.reduce(0, +) / Double(values.count)
    }
    
    private func calculateMin() -> Double? {
        guard statDefinition.measurementType != .text else { return nil }
        return statDefinition.measurements
            .compactMap { Double($0.value)}.min() ?? 0
    }
    
    private func calculateMax() -> Double? {
        guard statDefinition.measurementType != .text else { return nil }
        return statDefinition.measurements
            .compactMap { Double($0.value)}.max() ?? 0
    }
    
    private func calculateTrend() -> Double? {
        guard statDefinition.measurementType != .text, statDefinition.measurements.count >= 2 else { return nil }
        let sortedMeasurements = statDefinition.measurements.sorted(by: { $0.date < $1.date })
        if let firstValue = sortedMeasurements.first?.value,
           let lastValue = sortedMeasurements.last?.value,
           let first = Double(firstValue),
           let last = Double(lastValue) {
            return last - first
        }
        return nil
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
    StatDetailView(person: Person(name: "Dummy Person"), statDefinition: StatDefinition(id:UUID(), name: "Name", measurementType: MeasurementType.digit, systemImage:"ruler.fill", category: StatCategory(name: "Body")) )
}
