import SwiftUI

struct SpeechInputExampleView: View {
    @State private var committedText: String = ""
    @State private var volatileText: String = ""
    @State private var isRecording = false
    @State private var isPaused = false
    @State private var reportVolatile = true
    @State private var status: String = "Idle"
    @State private var alerts: (show: Bool, message: String) = (false, "")
    @State private var events: [String] = []
    @State private var streamTask: Task<Void, Never>? = nil
    private let manager = SpeechInputManager()

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                Text(displayText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxHeight: 280)

            Toggle("Report partial results", isOn: $reportVolatile)

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

            VStack(alignment: .leading, spacing: 8) {
                Text("Status: \(status)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Events")
                    .font(.headline)
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(events.suffix(50), id: \.self) { line in
                            Text(line).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 180)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .navigationTitle("Speech Input")
        .onDisappear { stop() }
        .onAppear { hookEvents() }
        .alert("Speech Error", isPresented: $alerts.show) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alerts.message)
        }
    }

    @MainActor
    private func start() {
        committedText = ""
        volatileText = ""
        isPaused = false
        isRecording = true
        streamTask?.cancel()
        streamTask = Task {
            do {
                status = "Starting..."
                let stream = try await manager.start(locale: .current, reportVolatile: reportVolatile)
                status = "Listening"
                for await result in stream {
                    if result.isFinal {
                        committedText += (committedText.isEmpty ? "" : "\n") + String(result.text.characters)
                        volatileText = ""
                    } else {
                        volatileText = String(result.text.characters)
                    }
                }
                status = "Stopped"
            } catch {
                isRecording = false
                status = "Error"
                alerts = (true, error.localizedDescription)
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

    private var displayText: AttributedString {
        AttributedString(committedText + (volatileText.isEmpty ? "" : "\n" + volatileText))
    }

    private func hookEvents() {
        manager.onEvent = { event in
            // Hop to the main actor to mutate view state safely
            Task { @MainActor in
                handle(event: event)
            }
        }
    }

    @MainActor
    private func handle(event: SpeechInputManager.Event) {
        switch event {
        case .stateChanged(let s):
            status = String(describing: s).capitalized
            events.append("stateChanged: \(s)")
        case .permissionsChecked(let mic, let speech):
            events.append("permissions: mic=\(mic), speech=\(speech.map(String.init) ?? "n/a")")
        case .modelInstallStarted(let loc):
            events.append("model install started: \(loc.identifier(.bcp47))")
        case .modelInstallCompleted(let loc):
            events.append("model install completed: \(loc.identifier(.bcp47))")
        case .analyzerReady:
            events.append("analyzer ready")
        case .engineStarted:
            events.append("engine started")
        case .engineStopped:
            events.append("engine stopped")
        case .recognitionStarted(let legacy):
            events.append("recognition started legacy=\(legacy)")
        case .info(let msg):
            events.append("info: \(msg)")
        case .warning(let msg):
            events.append("warning: \(msg)")
        case .error(let msg):
            events.append("error: \(msg)")
            alerts = (true, msg)
        }
    }
}

#Preview {
    NavigationStack { SpeechInputExampleView() }
}
