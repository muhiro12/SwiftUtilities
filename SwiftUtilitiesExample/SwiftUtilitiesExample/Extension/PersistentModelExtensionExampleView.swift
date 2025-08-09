import SwiftUI
import SwiftData

struct PersistentModelExtensionExampleView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var item: Item?

    var body: some View {
        VStack(spacing: 16) {
            if let item {
                Text("Item created at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                Button("Delete Item") {
                    item.delete()
                    self.item = nil
                }
            } else {
                Button("Create Item") {
                    let newItem = Item(timestamp: Date())
                    modelContext.insert(newItem)
                    item = newItem
                }
            }
        }
        .padding()
    }
}

#Preview {
    PersistentModelExtensionExampleView()
        .modelContainer(for: Item.self, inMemory: true)
}
