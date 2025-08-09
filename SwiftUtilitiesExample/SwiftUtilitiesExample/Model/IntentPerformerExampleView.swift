import SwiftUI

struct EchoPerformer: IntentPerformer {
    static func perform(_ input: String) async throws -> String {
        input
    }
}

struct IntentPerformerExampleView: View {
    @State private var output: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Button("Perform") {
                Task {
                    output = (try? await EchoPerformer.perform("hello")) ?? ""
                }
            }
            Text(output)
        }
        .padding()
    }
}

#Preview {
    IntentPerformerExampleView()
}
