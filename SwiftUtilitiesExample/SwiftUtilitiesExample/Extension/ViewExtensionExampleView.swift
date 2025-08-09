import SwiftUI

struct ViewExtensionExampleView: View {
    @State private var isHidden: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Text("This text can be hidden")
                .hidden(isHidden)
            Button(isHidden ? "Show" : "Hide") {
                isHidden.toggle()
            }
        }
        .padding()
    }
}

#Preview {
    ViewExtensionExampleView()
}
