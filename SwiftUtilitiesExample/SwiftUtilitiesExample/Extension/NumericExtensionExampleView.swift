import SwiftUI

struct NumericExtensionExampleView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("0.isZero: \(0.isZero.description)")
            Text("1.isNotZero: \(1.isNotZero.description)")
        }
        .padding()
    }
}

#Preview {
    NumericExtensionExampleView()
}
