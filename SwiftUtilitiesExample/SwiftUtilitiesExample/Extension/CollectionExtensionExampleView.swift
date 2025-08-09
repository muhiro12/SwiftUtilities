import SwiftUI

struct CollectionExtensionExampleView: View {
    let array = [1, 2, 3]

    var body: some View {
        VStack(spacing: 8) {
            Text("Array.empty.count: \(Array<Int>.empty.count)")
            Text("array.isNotEmpty: \(array.isNotEmpty.description)")
        }
        .padding()
    }
}

#Preview {
    CollectionExtensionExampleView()
}
