//  SpeechRecognizerExampleView.swift
//  SwiftUtilitiesExample
//  Created by Assistant on 2025/08/09.

import SwiftUI
import SwiftUtilities

struct SpeechRecognizerExampleView: View {
    @State private var recognizedText: String = ""
    @State private var isRecognizing: Bool = false
    @State private var errorMessage: String?
    @State private var partialTexts: [String] = []

    private let recognizer = SpeechRecognizer()

    var body: some View {
        VStack(spacing: 24) {
            Text("音声認識デモ")
                .font(.title2)
            Button(action: {
                requestAuthAndRecognizeOnce()
            }) {
                Text("1回だけ認識 (await)")
            }
            Text("認識結果: \(recognizedText)")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            Divider()

            Button(action: {
                isRecognizing.toggle()
                if isRecognizing {
                    partialTexts = []
                    requestAuthAndStreamRecognition()
                }
            }) {
                Text(isRecognizing ? "逐次認識停止" : "逐次認識開始 (AsyncSequence)")
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("逐次認識結果:")
                ForEach(partialTexts, id: \.self) { txt in
                    Text("• \(txt)").font(.caption)
                }
            }
            .padding(.horizontal)

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
        .padding()
    }

    private func requestAuthAndRecognizeOnce() {
        Task {
            let authorized = await SpeechRecognizer.requestAuthorization()
            guard authorized else {
                errorMessage = "音声認識の許可がありません。"
                return
            }
            do {
                let text = try await recognizer.recognizeOnce()
                recognizedText = text
                errorMessage = nil
            } catch {
                errorMessage = String(describing: error)
            }
        }
    }

    private func requestAuthAndStreamRecognition() {
        Task {
            let authorized = await SpeechRecognizer.requestAuthorization()
            guard authorized else {
                errorMessage = "音声認識の許可がありません。"
                isRecognizing = false
                return
            }
            do {
                let stream = await recognizer.recognitionStream()
                for try await text in stream {
                    partialTexts.append(text)
                }
                isRecognizing = false
            } catch {
                errorMessage = String(describing: error)
                isRecognizing = false
            }
        }
    }
}

#Preview {
    SpeechRecognizerExampleView()
}
