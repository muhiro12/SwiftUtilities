import SwiftUI
import SwiftData

struct ModelContextExtensionExampleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var fetchedItem: Item?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Add Item") {
                    let newItem = Item(timestamp: Date())
                    modelContext.insert(newItem)
                }
                Button("Fetch First") {
                    fetchedItem = try? modelContext.fetchFirst(FetchDescriptor<Item>())
                }
                Button("Fetch Random") {
                    fetchedItem = try? modelContext.fetchRandom(FetchDescriptor<Item>())
                }
            }
            if let fetchedItem {
                Text("Fetched: \(fetchedItem.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
            }
            List {
                ForEach(items) { item in
                    Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(items[index])
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ModelContextExtensionExampleView()
        .modelContainer(for: Item.self, inMemory: true)
}
