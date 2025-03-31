//
//  MainPanel.swift
//  MyStats
//
//  Created by Ярослав Краснокутский on 25.1.25..
//

import SwiftUI
import SwiftData

enum MainPanelDestination: Identifiable, Hashable {
    case addPerson
    case showStatView(stat: StatDefinition)
    case addStat
    var id: String {
        switch self {
        case .addPerson:
            return "addPerson"
        case .showStatView(let stat):
            return "showStatView-\(stat.id)"
        case .addStat:
            return "addStat"
        }
    }
}

struct MainPanel: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [Person]
    @Query private var categories: [StatCategory]
    @State private var selectedPersonId: UUID? // should not be optional !!!
    @State private var showingAddPerson = false
    //@State private var showingAddStat = false
    @State private var newPersonName = ""
    @State private var searchText = ""
    @State private var scrollOffset: CGFloat = 0
    @State private var path: [MainPanelDestination] = []
    
    var body: some View {
        NavigationStack(path: $path ) {
            VStack(spacing: 0) {
                if people.isEmpty {
                    ContentUnavailableView("No People", 
                        systemImage: "person.slash",
                        description: Text("Add a person to start tracking their stats")
                    )
                } else {
                    HStack (spacing: 2){
                        Button(action: {
                            path.append(.addPerson)
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                        }
                        .offset(y: 6)
                        personPicker
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            path.append(.addStat)
                        } label: {
                            Text("Add new stat")
                        }
                    }
                    if let personId = selectedPersonId {
                        statsGrid(for: personId)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("My Stats"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        path.append(.addPerson)
                        showingAddPerson = true
                    }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
                
                if selectedPersonId != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            path.append(.addStat)
                            //showingAddStat = true
                        }
                        label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .navigationDestination(for: MainPanelDestination.self) { destanation in
                switch destanation {
                case .addPerson:
                    addPersonSheet
                    //Text("Add Person")
                case .showStatView(let stat):
                    if let personId = selectedPersonId {
                        StatDetailView(personId: personId, statDefinition: stat)
                    }
                case .addStat:
                    Text("heelo")
                    if let personId = selectedPersonId {
                        AddStatView(personId: personId)
                    }
                }
                //addPersonSheet
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
        let stats = [StatDefinition(name: "Wight", measurementType: .decimal, categoryId: UUID()),
                     StatDefinition(name: "Height", measurementType: .decimal, categoryId: UUID()),
                     StatDefinition(name: "Weight", measurementType: .decimal, categoryId: UUID()),
                     StatDefinition(name: "Arm", measurementType: .decimal, categoryId: UUID()),]
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
                           
                            StatItemView(stat: stat, path: $path)
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
        //NavigationStack {
            Form {
                TextField("Person Name", text: $newPersonName)
            }
            .navigationTitle("Add Person")
            .navigationBarItems(
                trailing: Button("Add") {
                    if !newPersonName.isEmpty {
                        addNewPerson(name: newPersonName)
                    }
                    path.removeLast()
                }
            )
       // }
    }
    
    // MARK: - Helper Views
    
//    private func personButton(for person: Person) -> some View {
//        Button(action: {
//            selectedPersonId = person.id
//        }) {
//            Text(person.name)
//                .padding(.horizontal, 16)
//                .padding(.vertical, 8)
//                .background(
//                    selectedPersonId == person.id ?
//                    Color.blue : Color.gray.opacity(0.2)
//                )
//                .foregroundColor(
//                    selectedPersonId == person.id ?
//                    .white : .primary
//                )
//                .cornerRadius(20)
//        }
//    }
    
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
    let stat: StatDefinition
    @Binding var path: [MainPanelDestination]
    var body: some View {
        VStack {
            Image(systemName: stat.systemImage)
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            Text(getLatestValue(for: stat))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            Text(stat.name)
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
        .onTapGesture {
            path.append(.showStatView(stat: stat))
        }
    }
    
    private func getLatestValue(for stat: StatDefinition) -> String {
        guard let lastMeasurement = stat.measurements.last else {
            switch stat.measurementType {
            case .text:
                return stat.name
            case .integer:
                return "0"
            case .decimal:
                return "0.0"
            @unknown default:
                fatalError("Unsupported measurement type")
            }
        }
        
        return lastMeasurement.textValue ?? "No value"
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
