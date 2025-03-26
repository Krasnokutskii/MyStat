import SwiftUI
import SwiftData

struct AddStatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [StatCategory]
    
    let personId: UUID
    
    @State private var statName = ""
    @State private var measurementType = MeasurementType.decimal
    @State private var step = "1.0"
    //@State private var initialValue = "0"
    @State private var selectedImage = "ruler.fill"
    @State private var selectedCategoryId: UUID?
    @State private var showingImagePicker = false
    
    private let availableImages = [
        "ruler.fill", "scalemass", "heart.fill", "figure.arms.open",
        "tshirt.fill", "person.fill", "figure.walk", "drop.fill",
        "circle", "crown.fill", "eyeglasses", "person.crop.circle"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Stat Name", text: $statName)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Category", selection: $selectedCategoryId) {
                        Text("Select Category").tag(nil as UUID?)
                        ForEach(categories) { category in
                            Text(category.name).tag(category.id as UUID?)
                        }
                    }
                }
                
                Section("Measurement Settings") {
                    Picker("Type", selection: $measurementType) {
                        ForEach(MeasurementType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    if measurementType != .text {
                        HStack {
                            Text("Step")
                            TextField("Step Value", text: $step)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                Section("Icon") {
                    Button(action: { showingImagePicker = true }) {
                        HStack {
                            Image(systemName: selectedImage)
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Select Icon")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("New Stat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addStat()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                NavigationStack {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 60))
                    ], spacing: 20) {
                        ForEach(availableImages, id: \.self) { image in
                            Button {
                                selectedImage = image
                                showingImagePicker = false
                            } label: {
                                Image(systemName: image)
                                    .font(.title)
                                    .frame(width: 60, height: 60)
                                    .background(selectedImage == image ? Color.blue.opacity(0.2) : Color.clear)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .navigationTitle("Select Icon")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingImagePicker = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var isValid: Bool {
        !statName.isEmpty && 
        selectedCategoryId != nil &&
        (measurementType == .text || Double(step) != nil)
    }
    
    private func addStat() {
        guard let categoryId = selectedCategoryId else { return }
        
        //let stepValue = measurementType == .text ? 1.0 : Double(step) ?? 1.0
        
        let newStat = StatDefinition(
            name: statName,
            measurementType: measurementType,
            systemImage: selectedImage,
            categoryId: categoryId
        )
        
        if let person = try? modelContext.fetch(FetchDescriptor<Person>(
            predicate: #Predicate<Person> { person in
                person.id == personId
            }
        )).first {
            person.stats.append(newStat)
        }
        
        dismiss()
    }
} 
