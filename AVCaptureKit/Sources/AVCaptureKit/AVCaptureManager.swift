//
//  AVCaptureManager.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/23.
//

import Foundation
import AVFoundation
import Combine

public class AVCaptureManager: NSObject, ObservableObject {
    private let discoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: AVCaptureManager.deviceTypes,
        mediaType: nil,
        position: .unspecified
    )

    private let captureSessionActor = CaptureSessionActor()

    @MainActor
    public var captureSession: AVCaptureSession {
        captureSessionActor._captureSession
    }

    private var anyCancellables: Set<AnyCancellable> = []
    private var videoCaptureDeviceObservations: Set<NSObject?> = []

    @Published
    public private(set) var error: Error?

    @Published
    public var videoCaptureDevice: AVCaptureDevice? {
        willSet {
            videoCaptureDeviceObservations = [
                newValue?.observe(\.formats, options: [.prior]) { [objectWillChange] _, changes in
                    DispatchQueue.main.async {
                        objectWillChange.send()
                    }
                },
                newValue?.observe(\.activeFormat, options: [.prior]) { [objectWillChange] _, changes in
                    DispatchQueue.main.async {
                        objectWillChange.send()
                    }
                },
                newValue?.observe(\.activeVideoMinFrameDuration, options: [.prior]) { [objectWillChange] _, changes in
                    DispatchQueue.main.async {
                        objectWillChange.send()
                    }
                },
            ]
        }
        didSet {
            Task { [weak self, oldValue, videoCaptureDevice] in
                do {
                    try await captureSessionActor.updateDevice(oldDevice: oldValue, newDevice: videoCaptureDevice)
                } catch{
                    self?.error = error
                }
            }
        }
    }

    @Published
    public var audioCaptureDevice: AVCaptureDevice? {
        didSet {
            Task { [weak self, oldValue, audioCaptureDevice] in
                do {
                    try await captureSessionActor.updateDevice(oldDevice: oldValue, newDevice: audioCaptureDevice)
                } catch{
                    self?.error = error
                }
            }
        }
    }

    #if os(macOS)
    private let audioPreviewOutput = AVCaptureAudioPreviewOutput()

    @Published
    public var isAudioPreviewing: Bool = false {
        willSet {
            if isAudioPreviewing, !newValue {
                Task {
                    await captureSessionActor.configureSession { captureSession in
                        captureSession.removeOutput(audioPreviewOutput)
                    }
                }
            }
        }
        didSet {
            if !oldValue, isAudioPreviewing {
                Task {
                    await captureSessionActor.configureSession { captureSession in
                        captureSession.addOutput(audioPreviewOutput)
                    }
                }
            }
        }
    }
    #endif

    @Published
    public var movieFileOutputDestinationURL: URL? = {
        #if os(iOS)
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        #else
        FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first?.resolvingSymlinksInPath() ?? URL(filePath: NSHomeDirectory())
        #endif
    }()

    @Published
    public var movieFileOutputFilenameFormat: String = "AVCapture %yyyy-%MM-%dd %HH.%mm.%ss"

    @Published
    public var movieFileVideoOutputSettings = VideoOutputSettings() {
        didSet {
            Task {
                await updateVideoOutputSettings()
            }
        }
    }
    @Published
    public var movieFileAudioOutputSettings = AudioOutputSettings() {
        didSet {
            Task {
                await updateAudioOutputSettings()
            }
        }
    }

    @Published
    public var isMovieFileOutputRecording: Bool = false

    public override init() {
        super.init()

        discoverySession
            .publisher(for: \.devices)
            .receive(on: RunLoop.main)
            .sink { [objectWillChange] _ in
                objectWillChange.send()
            }
            .store(in: &anyCancellables)

        Task {
            await captureSessionActor.initializeCaptureSession()
        }
    }
}

extension AVCaptureManager {
    private static let deviceTypes: [AVCaptureDevice.DeviceType] = {
        #if os(iOS)
        return [.builtInWideAngleCamera, .builtInMicrophone]
        #else
        return [.builtInWideAngleCamera, .builtInMicrophone, .deskViewCamera, .externalUnknown]
        #endif
    }()
}

extension AVCaptureManager {
    public var availableDevices: [AVCaptureDevice] {
        discoverySession.devices
    }
    
    public var availableVideoDevices: [AVCaptureDevice] {
        availableDevices.filter {
            $0.hasMediaType(.video)
        }
    }
    
    public var availableAudioDevices: [AVCaptureDevice] {
        availableDevices.filter {
            $0.hasMediaType(.audio)
        }
    }
}

extension AVCaptureManager {
    public var videoCaptureDeviceFormats: [AVCaptureDevice.Format]? {
        videoCaptureDevice?.formats
    }

    public var videoCaptureDeviceFormat: AVCaptureDevice.Format? {
        get {
            videoCaptureDevice?.activeFormat
        }
        set {
            if let videoCaptureDevice, let newValue {
                Task {
                    do {
                        try await captureSessionActor.run { _ in
                            try videoCaptureDevice.lockForConfiguration()
                            videoCaptureDevice.activeFormat = newValue
                            videoCaptureDevice.unlockForConfiguration()
                        }
                    } catch {
                        self.error = error
                    }
                }
            }
        }
    }
}

extension AVCaptureManager {
    public var videoCaptureDeviceFrameDuration: CMTime? {
        get {
            videoCaptureDevice?.activeVideoMinFrameDuration
        }
        set {
            if let videoCaptureDevice, let newValue {
                Task {
                    do {
                        let newValue: CMTime = videoCaptureDevice.activeFormat.videoSupportedFrameRateRanges.reduce(
                            videoCaptureDevice.activeFormat.videoSupportedFrameRateRanges.reduce(newValue) { partialResult, frameRateRange in
                                CMTimeMinimum(partialResult, frameRateRange.maxFrameDuration)
                            }
                        ) { partialResult, frameRateRange in
                            CMTimeMaximum(partialResult, frameRateRange.minFrameDuration)
                        }

                        try await captureSessionActor.run { _ in
                            try videoCaptureDevice.lockForConfiguration()
                            videoCaptureDevice.activeVideoMinFrameDuration = newValue
                            videoCaptureDevice.activeVideoMaxFrameDuration = newValue
                            videoCaptureDevice.unlockForConfiguration()
                        }
                    } catch {
                        self.error = error
                    }
                }
            }
        }
    }

    public var videoCaptureDeviceFrameRate: Float64 {
        get {
            videoCaptureDeviceFrameDuration.flatMap { 1 / CMTimeGetSeconds($0) } ?? .nan
        }
        set {
            self.videoCaptureDeviceFrameDuration = CMTimeMake(value: Int64((1 / newValue * 600).rounded()), timescale: 600)
        }
    }
}

#if os(macOS)
extension AVCaptureManager {
    public var audioPreviewOutputDeviceUniqueID: String? {
        get {
            audioPreviewOutput.outputDeviceUniqueID
        }
        set {
            objectWillChange.send()
            audioPreviewOutput.outputDeviceUniqueID = newValue
        }
    }

    public var audioPreviewOutputVolume: Float {
        get {
            audioPreviewOutput.volume
        }
        set {
            objectWillChange.send()
            audioPreviewOutput.volume = newValue
        }
    }
}
#endif

extension AVCaptureManager {
    public var availableVideoCodecs: [VideoOutputSettings.VideoCodec] {
        #if os(iOS)
        captureSessionActor._movieFileOutput.availableVideoCodecTypes.map {
            VideoOutputSettings.VideoCodec(type: $0)
        }
        #else
        VideoOutputSettings.VideoCodec.allCases
        #endif
    }
}

extension AVCaptureManager {
    public var currentMovieFileOutputFileURL: URL? {
        captureSessionActor._movieFileOutput.outputFileURL
    }

    public func movieFileOutputFileURL(date: Date = Date()) -> URL? {
        guard let movieFileOutputDestinationURL else {
            return nil
        }

        let dateFormatter = DateFormatter()

        let filename = movieFileOutputFilenameFormat
            .replacing(#/%(\w+)/#) { match in
                dateFormatter.dateFormat = String(match.1)

                return dateFormatter.string(from: date)
            }

        return movieFileOutputDestinationURL.appendingPathComponent(filename, conformingTo: UTType.quickTimeMovie)
    }

    func movieFileOutputMetadata(date: Date = Date()) -> [AVMetadataItem] {
        var metadata: [AVMetadataItem] = [
            AVMutableMetadataItem(identifier: .commonIdentifierCreationDate, value: date as NSDate )
        ]

        if let videoCaptureDevice {
            metadata += [
                AVMutableMetadataItem(identifier: .commonIdentifierMake, value: videoCaptureDevice.manufacturer as NSString ),
                AVMutableMetadataItem(identifier: .commonIdentifierModel, value: videoCaptureDevice.localizedName as NSString )
            ]
        }

        return metadata
    }
}

extension AVCaptureManager {
    private func updateVideoOutputSettings() async {
        await captureSessionActor.run { [movieFileVideoOutputSettings] captureSessionActor in
            captureSessionActor.configureSession { captureSession in
                if let videoConnection = captureSessionActor.movieFileOutput.connection(with: .video) {
                    captureSessionActor.movieFileOutput.setOutputSettings(nil, for: videoConnection)
                    var outputSettings = captureSessionActor.movieFileOutput.outputSettings(for: videoConnection)

                    if let videoCodec = movieFileVideoOutputSettings.videoCodec {
                        outputSettings[AVVideoCodecKey] = videoCodec.type

                        switch videoCodec {
                        case .proRes422, .proRes422LT, .proRes422HQ, .proRes422Proxy, .proRes4444, .proRes4444XQ:
                            if var compressionProperties = outputSettings[AVVideoCompressionPropertiesKey] as? [String: Any] {
                                compressionProperties[AVVideoMaxKeyFrameIntervalDurationKey] = nil
                                outputSettings[AVVideoCompressionPropertiesKey] = compressionProperties
                            }
                        case .h264:
                            break
                        case .hevc, .hevcWithAlpha:
                            break
                        case .jpeg:
                            break
                        case .other:
                            break
                        }
                    }

                    #if os(iOS)
                    for unsupportedOutputSettingsKey in Set(outputSettings.keys).subtracting(captureSessionActor.movieFileOutput.supportedOutputSettingsKeys(for: videoConnection)) {
                        outputSettings.removeValue(forKey: unsupportedOutputSettingsKey)
                    }
                    #endif

                    captureSessionActor.movieFileOutput.setOutputSettings(outputSettings, for: videoConnection)
                }
            }
        }
    }

    private func updateAudioOutputSettings() async {
        await captureSessionActor.run { [movieFileAudioOutputSettings] captureSessionActor in
            captureSessionActor.configureSession { captureSession in
                if let audioConnection = captureSessionActor.movieFileOutput.connection(with: .audio) {
                    captureSessionActor.movieFileOutput.setOutputSettings(nil, for: audioConnection)
                    var outputSettings = captureSessionActor.movieFileOutput.outputSettings(for: audioConnection)

                    if let format = movieFileAudioOutputSettings.format {
                        outputSettings[AVFormatIDKey] = format.id

                        switch format {
                        case .linearPCM:
                            break
                        case .mpeg4AAC:
                            break
                        case .appleLossless:
                            outputSettings[AVEncoderBitRatePerChannelKey] = nil
                        case .other:
                            break
                        }
                    }

                    #if os(iOS)
                    for unsupportedOutputSettingsKey in Set(outputSettings.keys).subtracting(captureSessionActor.movieFileOutput.supportedOutputSettingsKeys(for: audioConnection)) {
                        outputSettings.removeValue(forKey: unsupportedOutputSettingsKey)
                    }
                    #endif

                    captureSessionActor.movieFileOutput.setOutputSettings(outputSettings, for: audioConnection)
                }
            }
        }
    }
}

extension AVCaptureManager {
    public func record() async {
        await captureSessionActor.run { captureSessionActor in
            let date = Date()

            guard let movieFileOutputFileURL = movieFileOutputFileURL(date: date) else {
                isMovieFileOutputRecording = false
                return
            }

            captureSessionActor.movieFileOutput.metadata = movieFileOutputMetadata(date: date)
            captureSessionActor.movieFileOutput.startRecording(to: movieFileOutputFileURL, recordingDelegate: self)
        }
    }

    public func stopRecording() async {
        await captureSessionActor.run { captureSessionActor in
            captureSessionActor.movieFileOutput.stopRecording()
        }
    }
}

extension AVCaptureManager: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        Task {
            await MainActor.run {
                isMovieFileOutputRecording = true
            }
        }
    }

    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        defer {
            Task {
                await MainActor.run {
                    isMovieFileOutputRecording = false
                }
            }
        }

        if let error {
            self.error = error
        }
    }
}
