import SwiftUI

struct UIImageExtensionExampleView: View {
    @State private var appIcon: UIImage? = UIImage.appIcon

    var body: some View {
        VStack(spacing: 16) {
            if let icon = appIcon {
                Image(uiImage: icon)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text("No App Icon")
            }
            Button("Reload") {
                appIcon = UIImage.appIcon
            }
        }
        .padding()
    }
}

#Preview {
    UIImageExtensionExampleView()
}
