import Foundation
import SwiftData
import SwiftUI

@Model
class StatCategory {
    var id: UUID
    var name: String
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

@Model
class Person {
    var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade) var stats: [StatDefinition]
    @Relationship(deleteRule: .cascade) var categories: [StatCategory]
    var avatarIcon: String? // Add this property to your Person model
    
    init(id: UUID = UUID(), name: String, avatar: String? = nil) {
        self.id = id
        self.name = name
        self.stats = []
        self.categories = []
        self.avatarIcon = avatar
    }
    
    func addStats(_ stats: [StatDefinition]) {
        self.stats.append(contentsOf: stats)
    }
    
    func addCategories(_ categories: [StatCategory]) {
        self.categories.append(contentsOf: categories)
    }
    
    var statsByCategory: [(String, [StatDefinition])] {
        let grouped = Dictionary(grouping: stats) { stat in
            stat.category?.name ?? "Other"
        }
        return grouped
            .sorted { $0.key < $1.key }
    }
}

@Model
class StatDefinition {
    var id: UUID
    var name: String
    var measurementType: MeasurementType
    var step: Double
    var systemImage: String
    @Relationship(deleteRule: .cascade) var category: StatCategory?
    @Relationship(deleteRule: .cascade) var measurements: [StatMeasurement]
    
    var sortedMeasurements: [StatMeasurement] {
        measurements.sorted(by: { $0.date > $1.date })
    }
    
    init(id: UUID = UUID(), name: String, measurementType: MeasurementType, step: Double = 1.0, systemImage: String = "ruler.fill", category: StatCategory) {
        self.id = id
        self.name = name
        self.measurementType = measurementType
        self.step = step
        self.systemImage = systemImage
        self.category = category
        self.measurements = []
    }
}

enum MeasurementType: String, Codable, CaseIterable {
    case digit = "Digit"
    case text = "Text"
}

@Observable
class StatDefinitionStore {
    private var modelContext: ModelContext
    var categories: [StatCategory] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCategories()
    }
    
    private func loadCategories() {
        do {
            categories = try modelContext.fetch(FetchDescriptor<StatCategory>())
        } catch {
            print("Failed to fetch categories: \(error)")
        }
    }
    
    func addCategory(_ category: StatCategory) {
        modelContext.insert(category)
    }
    
    func getStatsForPerson(_ personId: UUID) -> [StatDefinition] {
        do {
            let descriptor = FetchDescriptor<Person>(
                predicate: #Predicate<Person> { person in
                    person.id == personId
                }
            )
            let person = try modelContext.fetch(descriptor).first
            return person?.stats ?? []
        } catch {
            print("Failed to fetch stats: \(error)")
            return []
        }
    }
    
    func addStat(_ stat: StatDefinition, for personId: UUID) {
        do {
            let descriptor = FetchDescriptor<Person>(
                predicate: #Predicate<Person> { person in
                    person.id == personId
                }
            )
            if let person = try modelContext.fetch(descriptor).first {
                person.stats.append(stat)
            }
        } catch {
            print("Failed to add stat: \(error)")
        }
    }
    
    static func initializeDefaultStatsForPerson(_ person: Person, categories: [StatCategory]) {
        guard let bodyCategory = categories.first(where: { $0.name == "Body" }),
              let clothesCategory = categories.first(where: { $0.name == "Clothes" }),
              let healthCategory = categories.first(where: { $0.name == "Health" }) else {
            return
        }
        
        let defaults: [StatDefinition] = [
            // Body measurements
            StatDefinition(name: "Height", measurementType: .digit, step: 0.5,  systemImage: "arrow.up.and.down", category: bodyCategory),
            StatDefinition(name: "Weight", measurementType: .digit, step: 0.1, systemImage: "scalemass", category: bodyCategory),
            StatDefinition(name: "Waist", measurementType: .digit, step: 0.5, systemImage: "circle.dashed", category: bodyCategory),
            StatDefinition(name: "Chest", measurementType: .digit, step: 0.5,  systemImage: "person.crop.square.filled.and.at.rectangle", category: bodyCategory),
            StatDefinition(name: "Hips", measurementType: .digit, step: 0.5, systemImage: "figure.stand", category: bodyCategory),
            StatDefinition(name: "Shoulders", measurementType: .digit, step: 0.5, systemImage: "person.fill", category: bodyCategory),
            StatDefinition(name: "Neck", measurementType: .digit, step: 0.5, systemImage: "person.crop.circle.badge", category: bodyCategory),
            StatDefinition(name: "Biceps", measurementType: .digit, step: 0.5, systemImage: "figure.arms.open", category: bodyCategory),
            
            // Clothes sizes
            StatDefinition(name: "T-shirt", measurementType: .text, systemImage: "tshirt", category: clothesCategory),
            StatDefinition(name: "Trousers", measurementType: .text, systemImage: "figure.dress.line.vertical.figure", category: clothesCategory),
            StatDefinition(name: "Jacket", measurementType: .text, systemImage: "person.crop.square", category: clothesCategory),
            StatDefinition(name: "Shoe Size", measurementType: .text, systemImage: "shoe", category: clothesCategory),
            StatDefinition(name: "Hat/Cap", measurementType: .text, systemImage: "crown.fill", category: clothesCategory),
            StatDefinition(name: "Ring Size", measurementType: .text, systemImage: "circle", category: clothesCategory),
            
            // Health measurements
            StatDefinition(name: "Blood Pressure", measurementType: .text, systemImage: "heart.fill", category: healthCategory),
            StatDefinition(name: "Blood Group", measurementType: .text, systemImage: "drop.fill", category: healthCategory),
            StatDefinition(name: "BMI", measurementType: .digit, step: 0.1, systemImage: "function", category: healthCategory),
            StatDefinition(name: "Body Fat %", measurementType: .digit, step: 0.1, systemImage: "percent", category: healthCategory)
        ]
        
        defaults.forEach { stat in
            person.stats.append(stat)
        }
    }
} 

extension Array where Element: StatMeasurement {
    func lastByDate() -> StatMeasurement? {
        guard !isEmpty else { return nil }
        return self.max(by: { $0.date < $1.date })
    }
}
