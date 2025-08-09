import SwiftUI

struct OptionalExtensionExampleView: View {
    let optionalString: String? = "Hello"
    let emptyOptional: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Text("optionalString.isNotEmpty: \(optionalString.isNotEmpty.description)")
            Text("emptyOptional.orEmpty: \(emptyOptional.orEmpty)")
        }
        .padding()
    }
}

#Preview {
    OptionalExtensionExampleView()
}
