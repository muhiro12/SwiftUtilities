import SwiftUI

struct ColorExtensionExampleView: View {
    @State private var randomColor: Color = .random()
    @State private var adjustValue: Int = 0
    @State private var adjustedColor: Color = .random()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Random Color")
                Spacer()
                Circle()
                    .fill(randomColor)
                    .frame(width: 32, height: 32)
                Button("Change") {
                    randomColor = .random()
                    adjustedColor = randomColor.adjusted(by: adjustValue)
                }
            }
            HStack {
                Text("Adjusted Color")
                Spacer()
                Circle()
                    .fill(adjustedColor)
                    .frame(width: 32, height: 32)
                Stepper(value: $adjustValue, in: -30...30) {
                    Text("")
                }
                .onChange(of: adjustValue) { _, newValue in
                    adjustedColor = randomColor.adjusted(by: newValue)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ColorExtensionExampleView()
}
