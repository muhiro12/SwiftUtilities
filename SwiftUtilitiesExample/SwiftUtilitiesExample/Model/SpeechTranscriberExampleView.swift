import SwiftUI

struct SpeechTranscriberExampleView: View {
    @State private var onceText: String = ""
    @State private var isOneShotRunning = false

    @State private var streamText: String = ""
    @State private var isStreaming = false
    @State private var streamTask: Task<Void, Never>? = nil
    @State private var onDeviceOnly = true

    var body: some View {
        List {
            Section("設定") {
                Toggle("オンデバイス優先", isOn: $onDeviceOnly)
            }
            Section("One-shot (async/await)") {
                Text(onceText.isEmpty ? "—" : onceText)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                Button(isOneShotRunning ? "Listening…" : "Start One-Shot") {
                    guard !isOneShotRunning else { return }
                    isOneShotRunning = true
                    onceText = ""
                    Task {
                        defer { isOneShotRunning = false }
                        do {
                            let text = try await SpeechTranscriber.transcribeOnce(onDeviceOnly: onDeviceOnly)
                            onceText = text
                        } catch {
                            onceText = "Error: \(error.localizedDescription)"
                        }
                    }
                }
                .disabled(isOneShotRunning)
            }

            Section("Streaming (AsyncSequence)") {
                Text(streamText.isEmpty ? "—" : streamText)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                HStack {
                    Button(isStreaming ? "Listening…" : "Start Streaming") {
                        guard !isStreaming else { return }
                        isStreaming = true
                        streamText = ""
                        streamTask = Task {
                            do {
                                for try await item in SpeechTranscriber.transcriptions(onDeviceOnly: onDeviceOnly) {
                                    streamText = item.text
                                    if item.isFinal { break }
                                }
                            } catch {
                                streamText = "Error: \(error.localizedDescription)"
                            }
                            isStreaming = false
                        }
                    }
                    .disabled(isStreaming)

                    Button("Stop") {
                        streamTask?.cancel()
                        streamTask = nil
                        isStreaming = false
                    }
                    .disabled(!isStreaming)
                }
            }
        }
        .navigationTitle("SpeechTranscriber")
    }
}

#Preview {
    SpeechTranscriberExampleView()
}
