//
//  MyStatsApp.swift
//  MyStats
//
//  Created by Ярослав Краснокутский on 25.1.25..
//

import SwiftUI
import SwiftData

@main
struct MyStatsApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(
                for: Person.self, StatDefinition.self, StatCategory.self, StatMeasurement.self
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainPanel()
        }
        .modelContainer(container)
    }
}
