import SwiftUI

struct SpeechInputExampleView: View {
    @State private var transcribed: AttributedString = ""
    @State private var isRecording = false
    @State private var isPaused = false
    @State private var streamTask: Task<Void, Never>? = nil
    private let manager = SpeechInputManager()

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                Text(transcribed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxHeight: 280)

            HStack(spacing: 12) {
                Button(action: start) {
                    Label("Start", systemImage: "mic.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRecording)

                Button(action: stop) {
                    Label("Stop", systemImage: "stop.circle")
                }
                .buttonStyle(.bordered)
                .disabled(!isRecording)

                Button(action: togglePause) {
                    Label(isPaused ? "Resume" : "Pause", systemImage: isPaused ? "play.circle" : "pause.circle")
                }
                .buttonStyle(.bordered)
                .disabled(!isRecording)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Speech Input")
        .onDisappear { stop() }
    }

    @MainActor
    private func start() {
        transcribed = ""
        isPaused = false
        isRecording = true
        streamTask?.cancel()
        streamTask = Task {
            do {
                let stream = try await manager.start(locale: .current, reportVolatile: true)
                for await result in stream {
                    transcribed = result.text
                }
            } catch {
                isRecording = false
            }
        }
    }

    @MainActor
    private func stop() {
        isRecording = false
        isPaused = false
        streamTask?.cancel()
        streamTask = nil
        Task { await manager.stop() }
    }

    @MainActor
    private func togglePause() {
        guard isRecording else { return }
        if isPaused {
            do { try manager.resume(); isPaused = false } catch {}
        } else {
            manager.pause(); isPaused = true
        }
    }
}

#Preview {
    NavigationStack { SpeechInputExampleView() }
}

