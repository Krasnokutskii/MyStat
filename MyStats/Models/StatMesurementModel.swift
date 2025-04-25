//
//  StatMesurementModel.swift
//  MyStats
//
//  Created by Ярослав Краснокутский on 19. 4. 2025..
//

import Foundation
import SwiftData
import SwiftUI

@Model
class StatMeasurement {
    var id: UUID
    var date: Date
    var value: String
    
    init(id: UUID = UUID(), date: Date = Date(), value: String = "", textValue: String? = nil) {
        self.id = id
        self.date = date
        self.value = value
    }
}

@Observable
class StatStore {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getMeasurements(for personId: UUID, stat: String) -> [StatMeasurement] {
        do {
            let descriptor = FetchDescriptor<Person>(
                predicate: #Predicate<Person> { person in
                    person.id == personId
                }
            )
            if let person = try modelContext.fetch(descriptor).first,
               let statDef = person.stats.first(where: { $0.name == stat }) {
                return statDef.measurements
            }
        } catch {
            print("Failed to fetch measurements: \(error)")
        }
        return []
    }
    
//    func addMeasurement(for personId: UUID, stat: String, value: Double) {
//        let measurement = StatMeasurement(value: value)
//        addMeasurementToStore(for: personId, stat: stat, measurement: measurement)
//    }
    
//    func addTextMeasurement(for personId: UUID, stat: String, value: String) {
//        let measurement = StatMeasurement(value: 0, textValue: value)
//        addMeasurementToStore(for: personId, stat: stat, measurement: measurement)
//    }
    
//    private func addMeasurementToStore(for personId: UUID, stat: String, measurement: StatMeasurement) {
//        do {
//            let descriptor = FetchDescriptor<Person>(
//                predicate: #Predicate<Person> { person in
//                    person.id == personId
//                }
//            )
//            if let person = try modelContext.fetch(descriptor).first,
//               let statDef = person.stats.first(where: { $0.name == stat }) {
//                statDef.measurements.append(measurement)
//            }
//        } catch {
//            print("Failed to add measurement: \(error)")
//        }
//    }
}
