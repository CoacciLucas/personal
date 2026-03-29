import Speech
import AVFoundation
import ScreenCaptureKit
import CoreMedia

class SpeechService: NSObject {
    var onUserTranscriptUpdate: ((String) -> Void)?
    var onInterviewerTranscriptUpdate: ((String) -> Void)?
    var onError: ((String) -> Void)?

    private var speechRecognizer: SFSpeechRecognizer?

    // Mic (user)
    private let audioEngine = AVAudioEngine()
    private var micRequest: SFSpeechAudioBufferRecognitionRequest?
    private var micTask: SFSpeechRecognitionTask?
    private var micPreviousText = ""
    private var micTaskStartTime: Date?
    private var micRestartCount = 0
    private let maxRestarts = 5

    // System audio (interviewer)
    private var systemStream: SCStream?
    private var systemRequest: SFSpeechAudioBufferRecognitionRequest?
    private var systemTask: SFSpeechRecognitionTask?
    private var streamOutputHandler: StreamOutputHandler?
    private var systemPreviousText = ""
    private var systemTaskStartTime: Date?
    private var systemRestartCount = 0

    private(set) var userTranscript = ""
    private(set) var interviewerTranscript = ""
    private(set) var isListening = false

    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer()
    }

    // MARK: - Permissions

    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    completion(false)
                    return
                }
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            }
        }
    }

    // MARK: - Start / Stop

    func startListening() {
        guard !isListening else { return }
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            onError?("Reconhecimento de fala indisponivel")
            return
        }

        isListening = true
        userTranscript = ""
        interviewerTranscript = ""
        micPreviousText = ""
        systemPreviousText = ""
        micRestartCount = 0
        systemRestartCount = 0

        startMicRecognition()
        startSystemAudioCapture()
        print("[SpeechService] Listening started")
    }

    func stopListening() {
        guard isListening else { return }
        isListening = false

        // Stop mic
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        micRequest?.endAudio()
        micTask?.cancel()
        micRequest = nil
        micTask = nil

        // Stop system audio
        if let stream = systemStream {
            stream.stopCapture { _ in }
        }
        systemRequest?.endAudio()
        systemTask?.cancel()
        systemStream = nil
        systemRequest = nil
        systemTask = nil
        streamOutputHandler = nil

        print("[SpeechService] Listening stopped")
    }

    // MARK: - Microphone Recognition

    private func startMicRecognition() {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        micRequest = request
        micTaskStartTime = Date()

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard format.channelCount > 0, format.sampleRate > 0 else {
            print("[SpeechService] Invalid audio format: channels=\(format.channelCount) sampleRate=\(format.sampleRate)")
            DispatchQueue.main.async {
                self.onError?("Nenhum microfone detectado")
            }
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("[SpeechService] Audio engine failed: \(error)")
            DispatchQueue.main.async {
                self.onError?("Erro ao iniciar microfone: \(error.localizedDescription)")
            }
            return
        }

        let previousText = micPreviousText
        micTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self, self.isListening else { return }

            if let result {
                let partial = result.bestTranscription.formattedString
                let full = previousText.isEmpty ? partial : previousText + " " + partial
                self.userTranscript = full
                DispatchQueue.main.async {
                    self.onUserTranscriptUpdate?(full)
                }

                // Only restart if the task ran for a meaningful time and produced final results
                if result.isFinal {
                    self.micPreviousText = full
                    self.micRestartCount = 0 // Reset counter on successful session
                    self.tryRestartMic()
                }
            } else if let error {
                print("[SpeechService] Mic error: \(error.localizedDescription)")
                // Only restart if the task ran for at least 2 seconds (not an immediate failure)
                let elapsed = Date().timeIntervalSince(self.micTaskStartTime ?? Date())
                if elapsed > 2 {
                    self.micPreviousText = self.userTranscript
                    self.tryRestartMic()
                } else {
                    print("[SpeechService] Mic failed too quickly, not restarting")
                }
            }
        }
    }

    private func tryRestartMic() {
        guard isListening, micRestartCount < maxRestarts else {
            if micRestartCount >= maxRestarts {
                print("[SpeechService] Mic max restarts reached")
            }
            return
        }
        micRestartCount += 1

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        micRequest?.endAudio()
        micTask?.cancel()
        micRequest = nil
        micTask = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, self.isListening else { return }
            self.startMicRecognition()
            print("[SpeechService] Mic recognition restarted (\(self.micRestartCount)/\(self.maxRestarts))")
        }
    }

    // MARK: - System Audio Capture

    private func startSystemAudioCapture() {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                guard let display = content.displays.first else {
                    print("[SpeechService] No display found")
                    return
                }

                let filter = SCContentFilter(display: display, excludingWindows: [])
                let config = SCStreamConfiguration()
                config.capturesAudio = true
                config.excludesCurrentProcessAudio = true
                // Minimal video to reduce overhead
                config.width = 2
                config.height = 2
                config.minimumFrameInterval = CMTime(value: 1, timescale: 1)
                config.showsCursor = false

                let handler = StreamOutputHandler { [weak self] buffer in
                    self?.systemRequest?.append(buffer)
                }
                streamOutputHandler = handler

                let stream = SCStream(filter: filter, configuration: config, delegate: nil)
                // Register BOTH video and audio handlers to avoid "stream output NOT found" errors
                try stream.addStreamOutput(handler, type: .screen, sampleHandlerQueue: .global(qos: .background))
                try stream.addStreamOutput(handler, type: .audio, sampleHandlerQueue: .global(qos: .userInteractive))

                try await stream.startCapture()
                systemStream = stream

                startSystemRecognitionTask()
                print("[SpeechService] System audio capture started")
            } catch {
                print("[SpeechService] System audio setup failed: \(error)")
                DispatchQueue.main.async {
                    self.onError?("Audio do sistema indisponivel (verifique permissao de Gravacao de Tela)")
                }
            }
        }
    }

    private func startSystemRecognitionTask() {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        systemRequest = request
        systemTaskStartTime = Date()

        streamOutputHandler?.onAudioBuffer = { [weak request] buffer in
            request?.append(buffer)
        }

        let previousText = systemPreviousText
        systemTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self, self.isListening else { return }

            if let result {
                let partial = result.bestTranscription.formattedString
                let full = previousText.isEmpty ? partial : previousText + " " + partial
                self.interviewerTranscript = full
                DispatchQueue.main.async {
                    self.onInterviewerTranscriptUpdate?(full)
                }

                if result.isFinal {
                    self.systemPreviousText = full
                    self.systemRestartCount = 0
                    self.tryRestartSystemRecognition()
                }
            } else if let error {
                print("[SpeechService] System audio error: \(error.localizedDescription)")
                let elapsed = Date().timeIntervalSince(self.systemTaskStartTime ?? Date())
                if elapsed > 2 {
                    self.systemPreviousText = self.interviewerTranscript
                    self.tryRestartSystemRecognition()
                } else {
                    print("[SpeechService] System recognition failed too quickly, not restarting")
                }
            }
        }
    }

    private func tryRestartSystemRecognition() {
        guard isListening, systemRestartCount < maxRestarts else {
            if systemRestartCount >= maxRestarts {
                print("[SpeechService] System max restarts reached")
            }
            return
        }
        systemRestartCount += 1

        systemRequest?.endAudio()
        systemTask?.cancel()
        systemRequest = nil
        systemTask = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, self.isListening, self.systemStream != nil else { return }
            self.startSystemRecognitionTask()
            print("[SpeechService] System recognition restarted (\(self.systemRestartCount)/\(self.maxRestarts))")
        }
    }
}

// MARK: - Stream Output Handler

class StreamOutputHandler: NSObject, SCStreamOutput {
    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?

    init(onAudioBuffer: @escaping (AVAudioPCMBuffer) -> Void) {
        self.onAudioBuffer = onAudioBuffer
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        // Ignore video frames
        guard type == .audio else { return }
        guard CMSampleBufferGetNumSamples(sampleBuffer) > 0 else { return }
        guard CMSampleBufferDataIsReady(sampleBuffer) else { return }
        guard let buffer = convertToPCMBuffer(sampleBuffer) else { return }
        onAudioBuffer?(buffer)
    }

    private func convertToPCMBuffer(_ sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
        guard let formatDesc = sampleBuffer.formatDescription,
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) else { return nil }

        guard let format = AVAudioFormat(streamDescription: asbd) else { return nil }
        guard format.channelCount > 0 else { return nil }

        let frameCount = AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBuffer))
        guard frameCount > 0 else { return nil }
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        pcmBuffer.frameLength = frameCount

        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }

        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        let status = CMBlockBufferGetDataPointer(
            blockBuffer, atOffset: 0, lengthAtOffsetOut: nil,
            totalLengthOut: &length, dataPointerOut: &dataPointer
        )

        guard status == noErr, let srcData = dataPointer else { return nil }

        let audioBuffer = pcmBuffer.audioBufferList.pointee.mBuffers
        if let destData = audioBuffer.mData {
            memcpy(destData, srcData, min(length, Int(audioBuffer.mDataByteSize)))
        }

        return pcmBuffer
    }
}
