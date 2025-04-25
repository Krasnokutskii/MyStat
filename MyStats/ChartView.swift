import SwiftUI
import Charts

struct ChartView: View {
    let measurements: [StatMeasurement]
    
    private var sortedMeasurements: [StatMeasurement] {
        measurements.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        mainChart
            .chartXScale(domain: chartDomain)
            .chartYScale(domain: .automatic(includesZero: true))
            .chartXAxis(content: xAxis)
            .chartYAxis(content: yAxis)
            .chartBackground { proxy in
                ZStack {
                    Color.clear
                    Grid(horizontalSpacing: proxy.plotSize.width / 6,
                         verticalSpacing: proxy.plotSize.height / 5) {
                        ForEach(0..<6) { _ in
                            GridRow {
                                ForEach(0..<7) { _ in
                                    Color.secondary
                                        .opacity(0.1)
                                        .frame(width: 1, height: 1)
                                }
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .frame(height: 220)
            .padding(.vertical)
    }
    
    private var mainChart: some View {
        Chart(sortedMeasurements) { measurement in
            areaPlot(for: measurement)
            lineMark(for: measurement)
            dotMark(for: measurement)
        }
    }
    
    private func areaPlot(for measurement: StatMeasurement) -> some ChartContent {
        AreaMark(
            x: .value("Date", measurement.date),
            y: .value("Value", Double(measurement.value) ?? 0)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(
            LinearGradient(
                colors: [
                    .indigo.opacity(0.5),
                    .purple.opacity(0.2),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func lineMark(for measurement: StatMeasurement) -> some ChartContent {
        LineMark(
            x: .value("Date", measurement.date),
            y: .value("Value", Double(measurement.value) ?? 0)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(
            LinearGradient(
                colors: [.indigo, .purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .lineStyle(StrokeStyle(lineWidth: 2))
    }
    
    private func dotMark(for measurement: StatMeasurement) -> some ChartContent {
        PointMark(
            x: .value("Date", measurement.date),
            y: .value("Value", Double(measurement.value) ?? 0)
        )
        .foregroundStyle(.indigo.opacity(0.7))
        .symbolSize(28)
    }
    
    private func selectionAnnotation(for measurement: StatMeasurement) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(format: "%.1f", measurement.value))
                .font(.headline)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.indigo, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
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
            AxisTick()
            AxisGridLine()
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
            AxisTick()
            AxisGridLine()
        }
    }
} 

#Preview {
    ChartView(measurements: [StatMeasurement(id: UUID(), value: "10"),
                             StatMeasurement(id: UUID(),date: Date().addingTimeInterval(1),value: "20"),
                             StatMeasurement(id: UUID(), date: Date().addingTimeInterval(3), value: "150"),
                             StatMeasurement(id: UUID(), date: Date().addingTimeInterval(10), value: "400"),
                             StatMeasurement(id: UUID(), date: Date().addingTimeInterval(15), value: "50"),
                             StatMeasurement(id: UUID(), date: Date().addingTimeInterval(20), value: "-700"),
                             StatMeasurement(id: UUID(), date: Date().addingTimeInterval(25), value: "-90"),
                             StatMeasurement(id: UUID(), date: Date().addingTimeInterval(30), value: "10"),
                             StatMeasurement(id: UUID(), date: Date().addingTimeInterval(35), value: "30")])
        .frame(height: 300)
}
