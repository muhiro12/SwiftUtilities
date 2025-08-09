import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Component") {
                    NavigationLink("CloseButton") { CloseButtonExampleView() }
                }
                Section("Extension") {
                    NavigationLink("Color") { ColorExtensionExampleView() }
                    NavigationLink("Collection") { CollectionExtensionExampleView() }
                    NavigationLink("Image") { ImageExtensionExampleView() }
                    NavigationLink("ModelContext") { ModelContextExtensionExampleView() }
                    NavigationLink("Numeric") { NumericExtensionExampleView() }
                    NavigationLink("Optional") { OptionalExtensionExampleView() }
                    NavigationLink("PersistentIdentifier") { PersistentIdentifierExtensionExampleView() }
                    NavigationLink("PersistentModel") { PersistentModelExtensionExampleView() }
                    NavigationLink("StringProtocol") { StringProtocolExtensionExampleView() }
                    NavigationLink("UIImage") { UIImageExtensionExampleView() }
                    NavigationLink("View") { ViewExtensionExampleView() }
                }
                Section("Model") {
                    NavigationLink("IntentPerformer") { IntentPerformerExampleView() }
                    NavigationLink("SwiftUtilitiesError") { SwiftUtilitiesErrorExampleView() }
                    NavigationLink("SpeechTranscriber") { SpeechTranscriberExampleView() }
                }
            }
            .navigationTitle("SwiftUtilities Examples")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
