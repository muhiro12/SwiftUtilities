import SwiftUI

struct ImageExtensionExampleView: View {
    private let data = UIImage(systemName: "star")!.pngData() ?? Data()

    var body: some View {
        VStack(spacing: 16) {
            Image(data: data)
                .resizable()
                .frame(width: 64, height: 64)
        }
        .padding()
    }
}

#Preview {
    ImageExtensionExampleView()
}
