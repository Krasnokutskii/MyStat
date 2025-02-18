import Foundation
import SwiftData
import SwiftUI

@Model
class StatCategory {
    var id: UUID
    var name: String
    @Relationship(deleteRule: .nullify) var persons: [Person]
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.persons = []
    }
    
    static func createDefaultCategories(in modelContext: ModelContext) {
        let defaults = [
            StatCategory(name: "Body"),
            StatCategory(name: "Clothes"),
            StatCategory(name: "Health"),
            StatCategory(name: "Gym")
        ]
        
        defaults.forEach { category in
            modelContext.insert(category)
        }
    }
    
    static let defaultCategoryNames = [
        "Body",
        "Clothes",
        "Health",
        "Gym"
    ]
}

@Model
class Person {
    var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade) var stats: [StatDefinition]
    @Relationship(deleteRule: .nullify) var categories: [StatCategory]
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.stats = []
        self.categories = []
    }
}

@Model
class StatDefinition {
    var id: UUID
    var name: String
    var measurementType: MeasurementType
    var step: Double
    var initialValue: String
    var systemImage: String
    var categoryId: UUID
    @Relationship(deleteRule: .cascade) var measurements: [StatMeasurement]
    
    init(id: UUID = UUID(), name: String, measurementType: MeasurementType, step: Double = 1.0, initialValue: String = "0", systemImage: String = "ruler.fill", categoryId: UUID) {
        self.id = id
        self.name = name
        self.measurementType = measurementType
        self.step = step
        self.initialValue = initialValue
        self.systemImage = systemImage
        self.categoryId = categoryId
        self.measurements = []
    }
}

enum MeasurementType: String, Codable, CaseIterable {
    case integer = "Integer"
    case decimal = "Decimal"
    case text = "Text"
}

@Observable
class StatDefinitionStore {
    private var modelContext: ModelContext
    var categories: [StatCategory] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCategories()
        if categories.isEmpty {
            addDefaultCategories()
        }
    }
    
    private func loadCategories() {
        do {
            categories = try modelContext.fetch(FetchDescriptor<StatCategory>())
        } catch {
            print("Failed to fetch categories: \(error)")
        }
    }
    
    private func addDefaultCategories() {
        let defaults = [
            StatCategory(name: "Body"),
            StatCategory(name: "Clothes"),
            StatCategory(name: "Health"),
            StatCategory(name: "Gym")
        ]
        defaults.forEach { category in
            modelContext.insert(category)
        }
        categories = defaults
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
            StatDefinition(name: "Height", measurementType: .decimal, step: 0.5, initialValue: "180", systemImage: "arrow.up.and.down", categoryId: bodyCategory.id),
            StatDefinition(name: "Weight", measurementType: .decimal, step: 0.1, initialValue: "75", systemImage: "scalemass", categoryId: bodyCategory.id),
            StatDefinition(name: "Waist", measurementType: .decimal, step: 0.5, initialValue: "80", systemImage: "circle.dashed", categoryId: bodyCategory.id),
            StatDefinition(name: "Chest", measurementType: .decimal, step: 0.5, initialValue: "100", systemImage: "person.crop.square.filled.and.at.rectangle", categoryId: bodyCategory.id),
            StatDefinition(name: "Hips", measurementType: .decimal, step: 0.5, initialValue: "95", systemImage: "figure.stand", categoryId: bodyCategory.id),
            StatDefinition(name: "Shoulders", measurementType: .decimal, step: 0.5, initialValue: "45", systemImage: "person.fill", categoryId: bodyCategory.id),
            StatDefinition(name: "Neck", measurementType: .decimal, step: 0.5, initialValue: "38", systemImage: "person.crop.circle.badge", categoryId: bodyCategory.id),
            StatDefinition(name: "Biceps", measurementType: .decimal, step: 0.5, initialValue: "32", systemImage: "figure.arms.open", categoryId: bodyCategory.id),
            
            // Clothes sizes
            StatDefinition(name: "T-shirt", measurementType: .text, initialValue: "L", systemImage: "tshirt", categoryId: clothesCategory.id),
            StatDefinition(name: "Trousers", measurementType: .text, initialValue: "32", systemImage: "figure.dress.line.vertical.figure", categoryId: clothesCategory.id),
            StatDefinition(name: "Jacket", measurementType: .text, initialValue: "XL", systemImage: "person.crop.square", categoryId: clothesCategory.id),
            StatDefinition(name: "Shoe Size", measurementType: .text, initialValue: "42", systemImage: "shoe", categoryId: clothesCategory.id),
            StatDefinition(name: "Hat/Cap", measurementType: .text, initialValue: "58", systemImage: "crown.fill", categoryId: clothesCategory.id),
            StatDefinition(name: "Ring Size", measurementType: .text, initialValue: "18", systemImage: "circle", categoryId: clothesCategory.id),
            
            // Health measurements
            StatDefinition(name: "Blood Pressure", measurementType: .text, initialValue: "120/80", systemImage: "heart.fill", categoryId: healthCategory.id),
            StatDefinition(name: "Blood Group", measurementType: .text, initialValue: "A+", systemImage: "drop.fill", categoryId: healthCategory.id),
            StatDefinition(name: "BMI", measurementType: .decimal, step: 0.1, initialValue: "22.5", systemImage: "function", categoryId: healthCategory.id),
            StatDefinition(name: "Body Fat %", measurementType: .decimal, step: 0.1, initialValue: "15", systemImage: "percent", categoryId: healthCategory.id)
        ]
        
        defaults.forEach { stat in
            person.stats.append(stat)
        }
    }
} 
