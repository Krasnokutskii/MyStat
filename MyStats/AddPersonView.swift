//
//  AddPersonView.swift
//  MyStats
//
//  Created by Ярослав Краснокутский on 16.4.25..
//

import SwiftUI
import SwiftData

struct AddPersonView: View {
    @Binding var path: [MainPanelDestination]
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var age = ""
    @State private var selectedAvatar: String? // For default avatars
    @State private var showingAvatarOptions = false // To show avatar selection

    @FocusState private var focusedField: Field?

    enum Field {
        case name, weight, height, age, image
    }

    let defaultAvatars = ["person.fill", "figure.walk", "heart.fill", "leaf.fill", "flame.fill"]

    var body: some View {
            VStack(alignment: .leading, spacing: 18) {
                // Avatar
                VStack(spacing: 10) {
                    Button {
                        showingAvatarOptions = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 100, height: 100)
                            if let selectedAvatar = selectedAvatar {
                                Image(systemName: selectedAvatar)
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                            } else {
                                Text(name.isEmpty ? "?" : String(name.prefix(1)).uppercased())
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain) // Remove button styling
                    Text("Choose Avatar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .sheet(isPresented: $showingAvatarOptions) {
                    AvatarSelectionView(selectedAvatar: $selectedAvatar, showingSheet: $showingAvatarOptions)
                }

                // Basic Info Section
                VStack(alignment: .leading, spacing: 14) {
                    LabeledField(icon: "person.fill", placeholder: "Name", text: $name, field: .name)
                        .focused($focusedField, equals: .name)
                    LabeledField(icon: "scalemass.fill", placeholder: "Weight (kg)", text: $weight, field: .weight, keyboardType: .decimalPad, unit: "kg")
                        .focused($focusedField, equals: .weight)
                    LabeledField(icon: "figure.walk", placeholder: "Height (cm)", text: $height, field: .height, keyboardType: .decimalPad, unit: "cm")
                        .focused($focusedField, equals: .height)
                    LabeledField(icon: "calendar", placeholder: "Age", text: $age, field: .age, keyboardType: .numberPad)
                        .focused($focusedField, equals: .age)
                }
                .padding(.horizontal)

                Spacer()

                // Add Person Button
                Button(action: {
                    addNewPerson()
                    path.removeAll()
                }) {
                    Text("Add Person")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                .disabled(name.isEmpty || !isValidInput()) // Disable if name is empty or input is invalid
            }
            .navigationTitle("Create Profile")
            .background(Color(.systemGray6))
            .onTapGesture { hideKeyboard() }
            .padding(.bottom)
            .alert(isPresented: .constant(!isValidInput() && (!weight.isEmpty || !height.isEmpty || !age.isEmpty))) {
                Alert(title: Text("Invalid Input"), message: Text("Please enter valid numbers for weight, height, and age."), dismissButton: .default(Text("OK")))
            }
    }

    private func isValidInput() -> Bool {
        if !weight.isEmpty && Double(weight) == nil { return false }
        if !height.isEmpty && Double(height) == nil { return false }
        if !age.isEmpty && Int(age) == nil { return false }
        return true
    }

    private func addNewPerson() {
        guard !name.isEmpty && isValidInput() else {
            return
        }

        let person = Person(id: UUID(), name: name, avatar: selectedAvatar)

        let bodyCategory = StatCategory(id: UUID(), name: "Body")

        let heightStat = StatDefinition(name: "Height", measurementType: .digit, category: bodyCategory)
        let weightStat = StatDefinition(name: "Weight", measurementType: .digit, category: bodyCategory)
        let ageStat = StatDefinition(name: "Age", measurementType: .digit, category: bodyCategory)

        if let heightValue = Double(height) {
            heightStat.measurements.append(StatMeasurement(value: String(heightValue)))
        }
        if let weightValue = Double(weight) {
            weightStat.measurements.append(StatMeasurement(value: String(weightValue)))
        }
        if let ageValue = Int(age) {
            ageStat.measurements.append(StatMeasurement(value: String(ageValue)))
        }

        person.addCategories([
            bodyCategory,
            StatCategory(id: UUID(), name: "Clothes"),
            StatCategory(id: UUID(), name: "Health"),
            StatCategory(id: UUID(), name: "Gym")
        ])
        person.addStats([heightStat, weightStat, ageStat])

        modelContext.insert(person)
    }
}

struct LabeledField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var field: AddPersonView.Field
    @FocusState var focusedField: AddPersonView.Field?
    var keyboardType: UIKeyboardType = .default
    var unit: String? = nil

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue.opacity(0.9))
            TextField(placeholder, text: $text)
                .padding(.vertical, 12)
                .autocorrectionDisabled(true)
                .foregroundColor(.black)
                .tint(.blue)
                .keyboardType(keyboardType)
                .focused($focusedField, equals: field) // Use the passed in field
            if let unit = unit {
                Text(unit)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
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

struct AvatarSelectionView: View {
    @Binding var selectedAvatar: String?
    @Binding var showingSheet: Bool

    let defaultAvatars = ["person.fill", "figure.walk", "heart.fill", "leaf.fill", "flame.fill"]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                    ForEach(defaultAvatars, id: \.self) { avatar in
                        Button {
                            selectedAvatar = avatar
                            showingSheet = false
                        } label: {
                            VStack {
                                Image(systemName: avatar)
                                    .font(.largeTitle)
                                    .padding()
                                    .background(
                                        selectedAvatar == avatar ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1) // selected feedback
                                    )
                                    .clipShape(Circle())
                                Text(avatar.replacingOccurrences(of: "fill", with: "").capitalized) // show text
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Avatar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSheet = false
                    }
                }
            }
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    NavigationStack {
        AddPersonView(path: .constant([]))
    }
}

