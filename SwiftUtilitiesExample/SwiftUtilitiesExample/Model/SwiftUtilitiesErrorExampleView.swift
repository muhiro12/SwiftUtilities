import SwiftUI
import SwiftData

struct SwiftUtilitiesErrorExampleView: View {
    @State private var message: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Button("Trigger Error") {
                do {
                    _ = try PersistentIdentifier(base64Encoded: "invalid")
                } catch {
                    message = String(describing: error)
                }
            }
            Text(message)
        }
        .padding()
    }
}

#Preview {
    SwiftUtilitiesErrorExampleView()
}
