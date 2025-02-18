//
//  MainPanel.swift
//  MyStats
//
//  Created by Ярослав Краснокутский on 25.1.25..
//

import SwiftUI
import SwiftData

struct MainPanel: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [Person]
    @Query private var categories: [StatCategory]
    @State private var selectedPersonId: UUID?
    @State private var showingAddPerson = false
    @State private var showingAddStat = false
    @State private var newPersonName = ""
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if people.isEmpty {
                    ContentUnavailableView("No People", 
                        systemImage: "person.slash",
                        description: Text("Add a person to start tracking their stats")
                    )
                } else {
                    if isSearching {
                        searchField
                    }
                    personPicker
                    Spacer()
                    if let personId = selectedPersonId {
                        statsGrid(for: personId)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("My Stats"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !people.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { 
                            withAnimation {
                                isSearching.toggle()
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddPerson = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
                
                if selectedPersonId != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingAddStat = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddPerson) {
                addPersonSheet
            }
            .sheet(isPresented: $showingAddStat) {
                if let personId = selectedPersonId {
                    AddStatView(personId: personId)
                }
            }
        }
    }
    
    private var statsByCategory: [(String, [StatDefinition])] {
        guard let personId = selectedPersonId,
              let person = people.first(where: { $0.id == personId }) else { 
            return [] 
        }
        
        let grouped = Dictionary(grouping: person.stats) { stat in
            categories.first { $0.id == stat.categoryId }?.name ?? "Other"
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    private func addNewPerson(name: String) {
        let person = Person(name: name)
        
        // Link default person, categories, stats
        let stats = [StatDefinition(name: "wight", measurementType: .decimal, categoryId: UUID()),
                     StatDefinition(name: "height", measurementType: .decimal, categoryId: UUID()),
                     StatDefinition(name: "weigst", measurementType: .decimal, categoryId: UUID()),
                     StatDefinition(name: "arm", measurementType: .decimal, categoryId: UUID()),]
        person.categories = categories
        person.stats = stats
        categories.forEach { category in
            category.persons.append(person)
        }
        selectedPersonId = person.id
        modelContext.insert(person)
        newPersonName = ""
        showingAddPerson = false
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private func statsGrid(for personId: UUID) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(statsByCategory, id: \.0) { category, stats in
                    Section(header: categoryHeader(category)) {
                        ForEach(stats) { stat in
                            NavigationLink(destination: StatDetailView(
                                personId: personId,
                                statDefinition: stat
                            )) {
                                StatItemView(
                                    title: stat.name,
                                    value: getLatestValue(for: stat),
                                    systemImageName: stat.systemImage
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    
    private var statsExample: [String] {
        return person.stats.map { $0.name }
    }
    
    private var statValues: [String: (value: String, image: String)] {
        var values: [String: (value: String, image: String)] = [:]
        for stat in person.stats {
            values[stat.name] = (stat.initialValue, stat.systemImage)
        }
        return values
    }
    
    private var filteredStats: [String] {
        if searchText.count < 1 {
            return statsExample
        }
        return statsExample.filter { stat in
            stat.lowercased().contains(searchText.lowercased())
        }
    }
    
    private var person: Person {
        people.first(where: { $0.id == selectedPersonId }) ?? Person(name: "")
    }
    
    private var statDefinitionStore: StatDefinitionStore {
        StatDefinitionStore(modelContext: modelContext)
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var personPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GeometryReader { geometry in
                Color.clear.preference(key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scroll")).minY)
            }
            .frame(height: 0)
            
            VStack(spacing: 0) {
                personSelector
            }
            .padding(.top, 1)
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
        
//        if scrollOffset < -16 {
//            Text("My Stats")
//                .font(.headline)
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 8)
//                .background(Color(UIColor.systemBackground).opacity(0.9))
//                .transition(.move(edge: .top))
//        }
    }
    
    private var searchField: some View {
        TextField("Search", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
    }
    
    @State var isInEditMode: Bool = false
    private var personSelector: some View {
        HStack(spacing: 12) {
            ForEach(people) { person in
                PersonButton(
                    name: person.name,
                    isSelected: person.id == selectedPersonId,
                    isInEditMode: $isInEditMode,
                    action: {
                        selectedPersonId = person.id
                    },
                    onDelete: {
                        deletePerson(person)
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var addPersonSheet: some View {
        NavigationStack {
            Form {
                TextField("Person Name", text: $newPersonName)
            }
            .navigationTitle("Add Person")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingAddPerson = false
                },
                trailing: Button("Add") {
                    if !newPersonName.isEmpty {
                        addNewPerson(name: newPersonName)
                    }
                }
            )
        }
    }
    
    // MARK: - Helper Views
    
    private func personButton(for person: Person) -> some View {
        Button(action: {
            selectedPersonId = person.id
        }) {
            Text(person.name)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    selectedPersonId == person.id ?
                    Color.blue : Color.gray.opacity(0.2)
                )
                .foregroundColor(
                    selectedPersonId == person.id ?
                    .white : .primary
                )
                .cornerRadius(20)
        }
    }
    
    private var addPersonButton: some View {
        Button(action: {
            showingAddPerson = true
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
    }
    
    private func categoryHeader(_ category: String) -> some View {
        Text(category)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top)
    }
    
    // MARK: - Helper Methods
    
    private func getLatestValue(for stat: StatDefinition) -> String {
        guard let lastMeasurement = stat.measurements.last else {
            return stat.initialValue
        }
        
        if stat.measurementType == .text {
            return lastMeasurement.textValue ?? stat.initialValue
        } else {
            return String(format: "%.1f", lastMeasurement.value)
        }
    }
    
    private var statStore: StatDefinitionStore {
        StatDefinitionStore(modelContext: modelContext)
    }
    
    private func deletePerson(_ person: Person) {
        if person.id == selectedPersonId {
            selectedPersonId = people.first(where: { $0.id != person.id })?.id
        }
        modelContext.delete(person)
    }
}

// Custom view for stat item
struct StatItemView: View {
    let title: String
    let value: String
    let systemImageName: String
    
    var body: some View {
        VStack {
            Image(systemName: systemImageName)
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// Add this preference key for scroll offset tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    MainPanel()
}
