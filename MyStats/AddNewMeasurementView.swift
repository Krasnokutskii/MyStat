//
//  AddNewMeasurementView.swift
//  MyStats
//
//  Created by Ярослав Краснокутский on 29.3.25..
//

import SwiftUI

struct AddNewMeasurementView: View {
    @State private var newValue: String = ""
    @State private var showDatePicker: Bool = false {
        didSet {
            // Here
        }
    }
    @State private var selectedDate: Date = Date()
    @State private var appliedDate: Date?

    var statDefinition: StatDefinition //= StatDefinition(measurementType: .number) // Example

    private var formattedMonthAndDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        VStack(spacing: 12) {
            dateDisplay
            inputField
//            if showDatePicker {
//                //datePickerView
//                //Text("test")
//            }
            if showDatePicker {
                            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .transition(.opacity)
                        }
            Button {
                setMeasurement()
            } label: {
                Text("Set Value")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(statDefinition.measurementType == .text ? Color.blue : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        
        .padding(.vertical, 8)
    }

    private var datePickerView: some View {
        DatePicker("Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
    }

    private var inputField: some View {
        TextField("New Value", text: $newValue)
            .keyboardType(statDefinition.measurementType == .text ? .default : .decimalPad)
            .textFieldStyle(RoundedBorderTextFieldStyle())
    }

    private var dateDisplay: some View {
        HStack {
            Button{
                showDatePicker.toggle()
            } label: {
                Text(formattedMonthAndDay)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding(8)
    }

//    private var measurementButton: some View {
//        Button {
//            setMeasurement()
//        } label: {
//            Text("Set Value")
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(statDefinition.measurementType == .text ? Color.blue : Color.orange)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//        }
//    }
    
    private func setMeasurement() {
        let date = appliedDate != nil ? appliedDate : selectedDate
        //let date = selectedDate
        let measurement = StatMeasurement(
            date: date!,
            value: Double(newValue) ?? 0,
            textValue: statDefinition.measurementType == .text ? newValue : nil
        )
        statDefinition.measurements.append(measurement)
        newValue = ""
    }
    
//    private func setMeasurement() {
//        print("Measurement set: \(newValue)")
//    }
}

#Preview {
    AddNewMeasurementView(statDefinition: StatDefinition(name: "asdf", measurementType: .decimal, categoryId: UUID()))
}
