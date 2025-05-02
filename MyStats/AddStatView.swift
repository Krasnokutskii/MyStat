import SwiftUI

struct AddStatView: View {
    
    let person: Person
    
    @State private var statName = ""
    @State private var measurementType = MeasurementType.digit
    @State private var selectedImage = "ruler.fill"
    @State private var selectedCategory: StatCategory?
    @State private var showingImagePicker = false
    @Binding var path: [MainPanelDestination]
    @State private var inputValue = ""
    private let createNewCategory = StatCategory(id: UUID(), name: "➕ Create New")
    
    private let availableImages = [
        "ruler.fill", "scalemass", "heart.fill", "figure.arms.open",
        "tshirt.fill", "person.fill", "figure.walk", "drop.fill",
        "circle", "crown.fill", "eyeglasses", "person.crop.circle"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            basicInfoSection
                .padding(.horizontal)
            
            /*me*/
            //surementTypeSection
            ToggleTextField(value: $inputValue)
                .padding(.horizontal)
            
            iconSection
                .padding(.horizontal)
            
            Spacer()
            
            addStatButton
        }
        .navigationTitle("Add Stat")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.white)
        .sheet(isPresented: $showingImagePicker) {
            NavigationStack {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 20) {
                    ForEach(availableImages, id: \.self) { image in
                        Button {
                            selectedImage = image
                            showingImagePicker = false
                        } label: {
                            Image(systemName: image)
                                .font(.title)
                                .frame(width: 60, height: 60)
                                .background(selectedImage == image ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(12)
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
   
    private var addStatButton: some View {
        Button(action: {
            addStat()
        }) {
            Text("Add Stat")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValid ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
        .disabled(!isValid)
    }
    
    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                showingImagePicker = true
            } label: {
                HStack {
                    Image(systemName: selectedImage)
                        .font(.title2)
                        .foregroundColor(.blue.opacity(0.8))
                    Text("Select Icon")
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.blue.opacity(0.05), radius: 2, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                )
            }
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            StatItemView(stat: StatDefinition(name: statName, measurementType: measurementType, systemImage: selectedImage, category: selectedCategory ?? StatCategory(name: "default")), path: $path)
                .disabled(true)
                .padding(.top, 16)  // Top padding 16
                .padding(.leading, 40)  // Leading padding 20
                .padding(.trailing, 40)  // Trailing padding 20
                .padding(.bottom, 24)
            VStack(spacing: 12) {
                // Stat Name Field
                LabeledField(icon: selectedImage, placeholder: "Stat Name", text: $statName, field: .image)
                    .textInputAutocapitalization(.words)
                
                // Category Picker
                Menu {
                    ForEach(person.categories + [createNewCategory]) { category in
                        Button(category.name) {
                            selectedCategory = category
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue.opacity(0.8))
                        Text(selectedCategory?.name ?? "Select Category")
                            .foregroundColor(selectedCategory == nil ? .gray : .black)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.blue.opacity(0.05), radius: 2, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    private var mesurementTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Button {
                    measurementType = .digit
                } label: {
                    Text("Number")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(measurementType == .digit ? Color.blue : Color.gray.opacity(0.15))
                        .foregroundColor(measurementType == .digit ? .white : .black)
                        .cornerRadius(20)
                }
                
                Button {
                    measurementType = .text
                } label: {
                    Text("Text")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(measurementType == .text ? Color.blue : Color.gray.opacity(0.15))
                        .foregroundColor(measurementType == .text ? .white : .black)
                        .cornerRadius(20)
                }
                Spacer()
            }

//            TextField("Enter value", text: $measurementValue)
//                .keyboardType(measurementType == .digit ? .decimalPad : .default)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding(.horizontal)
        }
    }

    struct ToggleTextField: View {
        @Binding var value: String
        @State private var inputType: MeasurementType = .digit

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Input Type:")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 120, height: 36)

                        HStack(spacing: 0) {
                            Text("Digit")
                                .frame(width: 60, height: 36)
                            Text("Text")
                                .frame(width: 60, height: 36)
                        }

                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                                .frame(width: 60, height: 36)
                                .offset(x: inputType == .digit ? -30 : 30)
                                .animation(.easeInOut(duration: 0.25), value: inputType)
                        }

                        HStack(spacing: 0) {
                            Button {
                                inputType = .digit
                            } label: {
                                Text("Digit")
                                    .frame(width: 60, height: 36)
                                    .foregroundColor(inputType == .digit ? .white : .black)
                            }

                            Button {
                                inputType = .text
                            } label: {
                                Text("Text")
                                    .frame(width: 60, height: 36)
                                    .foregroundColor(inputType == .text ? .white : .black)
                            }
                        }
                    }
                }

                TextField("Enter value", text: $value)
                    .keyboardType(inputType == .digit ? .decimalPad : .default)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }



    private var isValid: Bool {
        !statName.isEmpty && selectedCategory != nil
    }
    
    private func addStat() {
        guard let selectedCategory = selectedCategory else { return }
        
        let newStat = StatDefinition(
            name: statName,
            measurementType: measurementType,
            systemImage: selectedImage,
            category: selectedCategory
        )
        person.stats.append(newStat)
        path.removeLast()
    }
}

#Preview {
    NavigationStack {
        AddStatView(person: Person(name: "Dummy Person Name"), path: Binding.constant([]))
    }
}
