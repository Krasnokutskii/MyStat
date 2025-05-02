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
    @State private var selectedPerson: Person?
    @State private var showingAddPerson = false
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
                        .padding(5)
                        personPicker
                    }
                    Spacer()
                    searchField
                    Spacer()
                        .frame(height: 5)
                    if let person = selectedPerson {
                        statsGrid(for: person)
                        
                        Button(action: {
                            path.append(.addStat)
                        }) {
                            Text("New Stat")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("My Stats"))
            .navigationBarTitleDisplayMode(.inline)
            .padding(.bottom)
            .toolbar {
                if people.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            path.append(.addPerson)
                            showingAddPerson = true
                        }) {
                            Image(systemName: "person.badge.plus")
                        }
                    }
                }
            }
            .navigationDestination(for: MainPanelDestination.self) { destanation in
                switch destanation {
                case .addPerson:
                    AddPersonView(path: $path)
                case .showStatView(let stat):
                    if let person = selectedPerson {
                        StatDetailView(person: person, statDefinition: stat)
                    }
                case .addStat:
                    if let person = selectedPerson {
                        AddStatView(person: person, path: $path)
                    }
                }
            }
        }
    }
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private func statsGrid(for person: Person) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(person.statsByCategory.filter { category, stats in
                    // Only show categories that contain matching stats
                    searchText.isEmpty || stats.contains(where: {
                        $0.name.localizedCaseInsensitiveContains(searchText)
                    })
                }, id: \.0) { category, stats in
                    Section(header: categoryHeader(category)) {
                        ForEach(stats.filter { stat in
                            // Only show stats that match the search
                            searchText.isEmpty || stat.name.localizedCaseInsensitiveContains(searchText)
                        }) { stat in
                            StatItemView(stat: stat, path: $path)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    
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
        .padding(5)
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    @State var isInEditMode: Bool = false
    private var personSelector: some View {
        HStack(spacing: 12) {
            ForEach(people) { person in
                PersonButton(
                    name: person.name,
                    isSelected: person == selectedPerson,
                    isInEditMode: $isInEditMode,
                    action: {
                        selectedPerson = person
                    },
                    onDelete: {
                        deletePerson(person)
                    }
                )
            }
        }
        .padding(.horizontal)
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
    }
    
    // MARK: - Helper Methods
    
    private var statStore: StatDefinitionStore {
        StatDefinitionStore(modelContext: modelContext)
    }
    
    private func deletePerson(_ person: Person) {
        modelContext.delete(person)
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
    do {
        // Create an in-memory container for testing
        let container = try ModelContainer(for: Person.self, StatCategory.self, configurations: .init(isStoredInMemoryOnly: true))
        
        // Add mock data
        let context = container.mainContext
        let uuid = UUID()
        
        // Create and insert mock data into context
        let person = Person(id: uuid, name: "Alice")
        let category = StatCategory(id: uuid, name: "Work")
        
        context.insert(person)
        context.insert(category)
        
        // Optional: If you have relationships, make sure they're set up
        person.addCategories([category]) // If your person has categories

        // Return MainPanel with the mock container
        return MainPanel()
            .modelContainer(container) // Inject container into view
    } catch {
        return Text("Failed to load preview: \(error.localizedDescription)") // Handle errors
    }
}


