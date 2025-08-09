import SwiftUI

struct CloseButtonExampleView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Tap the close button to dismiss this view")
            CloseButton()
        }
        .padding()
    }
}

#Preview {
    CloseButtonExampleView()
}
