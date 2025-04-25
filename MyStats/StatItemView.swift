//
//  StatItemView.swift
//  MyStats
//
//  Created by Ярослав Краснокутский on 16.4.25..
//


import SwiftUI
import SwiftData

struct StatItemView: View {
    let stat: StatDefinition
    @Binding var path: [MainPanelDestination]
    var body: some View {
        VStack {
            Image(systemName: stat.systemImage)
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            Text(stat.measurements.lastByDate()?.value ?? "-")
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
}

#Preview {
    @Previewable @State var dummyPath: [MainPanelDestination] = []
    StatItemView(stat: StatDefinition(name: "Height", measurementType: .digit, category: StatCategory(name: "Body")), path: $dummyPath)
}
