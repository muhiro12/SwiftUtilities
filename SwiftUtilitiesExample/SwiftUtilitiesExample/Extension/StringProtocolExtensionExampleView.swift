import SwiftUI

struct StringProtocolExtensionExampleView: View {
    let source = "ＡＢＣｄｅｆ"

    var body: some View {
        VStack(spacing: 8) {
            Text("Source: \(source)")
            Text("Contains 'abc': \(source.normalizedContains("abc").description)")
        }
        .padding()
    }
}

#Preview {
    StringProtocolExtensionExampleView()
}
