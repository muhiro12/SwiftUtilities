//
//  ContentView.swift
//  SwiftUtilitiesExample
//
//  Created by Hiromu Nakano on 2025/08/09.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    @State private var randomColor: Color = .random()
    @State private var adjustValue: Int = 0 {
        didSet {
            adjustedColor = randomColor.adjusted(by: adjustValue)
        }
    }
    @State private var showHiddenSample: Bool = true
    @State private var fetchedItem: Item? = nil
    @State private var adjustedColor: Color = .random()
    @State private var appIcon: UIImage? = UIImage.appIcon

    var body: some View {
        NavigationSplitView {
            List {
                Section(header: Text("パッケージ機能サンプル")) {
                    // Color.random() サンプル
                    HStack {
                        Text("Random Color")
                        Spacer()
                        Circle()
                            .fill(randomColor)
                            .frame(width: 32, height: 32)
                        Button("Change") {
                            randomColor = Color.random()
                            adjustedColor = randomColor.adjusted(by: adjustValue)
                        }
                    }
                    // Color.adjusted サンプル
                    HStack {
                        Text("Adjusted Color")
                        Spacer()
                        Circle()
                            .fill(adjustedColor)
                            .frame(width: 32, height: 32)
                        Stepper(value: $adjustValue, in: -30...30) {
                            Text("")
                        }
                    }
                    // UIImage.appIcon サンプル
                    HStack {
                        Text("App Icon")
                        Spacer()
                        if let icon = appIcon {
                            Image(uiImage: icon)
                                .resizable()
                                .frame(width: 32, height: 32)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Text("-")
                        }
                    }
                    // CloseButton サンプル
                    NavigationLink("CloseButton Demo") {
                        VStack {
                            Text("CloseButton 動作確認")
                            CloseButton()
                        }
                        .padding()
                    }
                    // View.hidden サンプル
                    HStack {
                        Text("hidden(_:) Sample")
                        Spacer()
                        if showHiddenSample {
                            Text("Visible")
                        }
                        Button(showHiddenSample ? "Hide" : "Show") {
                            showHiddenSample.toggle()
                        }
                    }
                    // ModelContext.fetchFirst/fetchRandom サンプル
                    HStack {
                        Button("Fetch First") {
                            fetchFirstItem()
                        }
                        Button("Fetch Random") {
                            fetchRandomItem()
                        }
                    }
                    if let fetchedItem = fetchedItem {
                        Text("Fetched: \(fetchedItem.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    }
                }

                Section(header: Text("Item List")) {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .onAppear {
                appIcon = UIImage.appIcon
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }

    private func fetchFirstItem() {
        fetchedItem = try? modelContext.fetchFirst(FetchDescriptor<Item>())
    }

    private func fetchRandomItem() {
        fetchedItem = try? modelContext.fetchRandom(FetchDescriptor<Item>())
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
