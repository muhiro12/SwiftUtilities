@preconcurrency import AVFoundation

/// Lightweight audio buffer converter to match an `AVAudioFormat`.
/// Converts only when formats differ; otherwise returns the original buffer.
final class BufferConverter {
    enum ConversionError: Error {
        case failedToCreateConverter
        case failedToCreateBuffer
        case conversionFailed(NSError?)
    }

    private var converter: AVAudioConverter?

    func convert(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let inputFormat = buffer.format
        guard inputFormat != format else { return buffer }

        if converter == nil || converter?.outputFormat != format || converter?.inputFormat != inputFormat {
            converter = AVAudioConverter(from: inputFormat, to: format)
            converter?.primeMethod = .none
        }

        guard let converter else { throw ConversionError.failedToCreateConverter }

        let sampleRateRatio = converter.outputFormat.sampleRate / converter.inputFormat.sampleRate
        let scaledInputFrameLength = Double(buffer.frameLength) * sampleRateRatio
        let frameCapacity = AVAudioFrameCount(max(1, Int(scaledInputFrameLength.rounded(.up))))
        guard let out = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: frameCapacity) else {
            throw ConversionError.failedToCreateBuffer
        }

        var nsError: NSError?
        final class OneShotFlag: @unchecked Sendable { var provided = false }
        let flag = OneShotFlag()
        let status = converter.convert(to: out, error: &nsError) { _, inputStatus in
            if flag.provided {
                inputStatus.pointee = .noDataNow
                return nil
            } else {
                flag.provided = true
                inputStatus.pointee = .haveData
                return buffer
            }
        }

        guard status != .error else { throw ConversionError.conversionFailed(nsError) }
        return out
    }
}
