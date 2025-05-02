//
//  AddNewMeasurementView.swift
//  MyStats
//
//  Created by Ярослав Краснокутский on 29.3.25..
//

import SwiftUI

struct AddNewMeasurementView: View {
    @State private var newValue: String = ""
    @State private var showDatePicker: Bool = false
    @State private var selectedDate: Date = Date()
    @State private var userDidPickDate: Bool = false  // 🔸 NEW FLAG

    var statDefinition: StatDefinition

    private var formattedMonthDayYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        VStack(spacing: 12) {
            if showDatePicker {
                dateDisplay
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .onChange(of: selectedDate) { _, _ in
                        userDidPickDate = true
                    }
                    .datePickerStyle(.graphical)
                    .transition(.opacity)
            } else {
                dateDisplay
            }
            inputField

            Button {
                setMeasurement()
            } label: {
                Text("Set Value")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        newValue.isEmpty
                        ? Color.gray
                        : (statDefinition.measurementType == .text ? Color.blue : Color.orange)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(newValue.isEmpty)
        }
    }

    private var inputField: some View {
        TextField("New Value", text: $newValue)
            .keyboardType(statDefinition.measurementType == .text ? .default : .decimalPad)
            .textFieldStyle(RoundedBorderTextFieldStyle())
    }

    private var dateDisplay: some View {
        HStack {
            Button {
                showDatePicker.toggle()
            } label: {
                Text(formattedMonthDayYear)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

    private func setMeasurement() {
        let finalDate = userDidPickDate ? selectedDate : Date()

        let measurement = StatMeasurement(
            date: finalDate,
            value: newValue
        )

        statDefinition.measurements.append(measurement)
        newValue = ""
        showDatePicker = false
        userDidPickDate = false
        selectedDate = Date()
    }
}

#Preview {
    AddNewMeasurementView(statDefinition: StatDefinition(name: "asdf", measurementType: .digit, category: StatCategory(name: "Body")))
}
