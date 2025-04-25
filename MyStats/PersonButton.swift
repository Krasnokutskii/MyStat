import SwiftUI

struct PersonButton: View {
    let name: String
    let isSelected: Bool
    @Binding var isInEditMode: Bool
    let action: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(name)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.clear)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 1)
                )
                .onTapGesture {
                    action()
                }
                .onLongPressGesture(minimumDuration: 1.0) {
                    isInEditMode.toggle()
                }
            
            if isInEditMode {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .offset(x: 7, y: -5)
            }
        }
    }
}

#Preview {
    PersonButton(name: "John", isSelected: true, isInEditMode: .constant(true), action: {}, onDelete: {})
        .frame(width: 150, height: 10)
    
}
