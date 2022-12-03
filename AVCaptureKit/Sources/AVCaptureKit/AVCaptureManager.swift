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
    private static let deviceTypes: [AVCaptureDevice.DeviceType] = {
        #if os(iOS)
        return [.builtInWideAngleCamera, .builtInMicrophone]
        #else
        return [.builtInWideAngleCamera, .builtInMicrophone, .deskViewCamera, .externalUnknown]
        #endif
    }()

    private let discoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: AVCaptureManager.deviceTypes,
        mediaType: nil,
        position: .unspecified
    )
    
    public private(set) lazy var captureSession: AVCaptureSession = {
        let captureSession = AVCaptureSession()
        
        captureSession.beginConfiguration()
        
        #if os(iOS)
        if captureSession.isMultitaskingCameraAccessSupported {
            // Enable using the camera in multitasking modes.
            captureSession.isMultitaskingCameraAccessEnabled = true
        }
        #endif

        captureSession.addOutput(movieFileOutput)

        captureSession.commitConfiguration()
        
        return captureSession
    }()

    private var anyCancellables: Set<AnyCancellable> = []

    private var videoCaptureDeviceAnyCancellables: Set<AnyCancellable> = []
    
    @Published public var videoCaptureDevice: AVCaptureDevice? {
        willSet {
            videoCaptureDeviceAnyCancellables = []

            videoCaptureDevice?
                .publisher(for: \.formats)
                .sink { [objectWillChange] _ in
                    objectWillChange.send()
                }
                .store(in: &videoCaptureDeviceAnyCancellables)

            videoCaptureDevice?
                .publisher(for: \.activeFormat)
                .sink { [objectWillChange] _ in
                    objectWillChange.send()
                }
                .store(in: &videoCaptureDeviceAnyCancellables)

            updateCaptureSession(videoDevice: newValue, audioDevice: audioCaptureDevice)
        }
    }
    
    @Published public var audioCaptureDevice: AVCaptureDevice? {
        willSet {
            updateCaptureSession(videoDevice: videoCaptureDevice, audioDevice: newValue)
        }
    }
    
    #if os(macOS)
    private let audioPreviewOutput = AVCaptureAudioPreviewOutput()
    
    @Published public var isAudioPreviewing: Bool = false {
        willSet {
            if isAudioPreviewing, !newValue {
                self.captureSession.removeOutput(audioPreviewOutput)
            }
        }
        didSet {
            if !oldValue, isAudioPreviewing {
                self.captureSession.addOutput(audioPreviewOutput)
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

    @Published public var movieFileOutputFilenameFormat: String = "AVCapture %yyyy-%MM-%dd %HH.%mm.%ss"

    private let movieFileOutput = AVCaptureMovieFileOutput()

    @Published
    public var movieFileVideoOutputSettings = VideoOutputSettings() {
        didSet {
            updateVideoOutputSettings()
        }
    }
    @Published
    public var movieFileAudioOutputSettings = AudioOutputSettings() {
        didSet {
            updateAudioOutputSettings()
        }
    }

    @Published public var isMovieFileOutputRecording: Bool = false
    
    @Published public private(set) var error: Error?
    
    public override init() {
        super.init()
        
        discoverySession
            .publisher(for: \.devices)
            .sink { [objectWillChange] _ in
                objectWillChange.send()
            }
            .store(in: &anyCancellables)
        
        captureSession.startRunning()
    }
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
                do {
                    try videoCaptureDevice.lockForConfiguration()
                    videoCaptureDevice.activeFormat = newValue
                    videoCaptureDevice.unlockForConfiguration()
                } catch {
                    self.error = nil
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
                let newValue: CMTime = videoCaptureDevice.activeFormat.videoSupportedFrameRateRanges.reduce(
                    videoCaptureDevice.activeFormat.videoSupportedFrameRateRanges.reduce(newValue) { partialResult, frameRateRange in
                        CMTimeMinimum(partialResult, frameRateRange.maxFrameDuration)
                    }
                ) { partialResult, frameRateRange in
                    CMTimeMaximum(partialResult, frameRateRange.minFrameDuration)
                }
                
                do {
                    try videoCaptureDevice.lockForConfiguration()
                    videoCaptureDevice.activeVideoMinFrameDuration = newValue
                    videoCaptureDevice.activeVideoMaxFrameDuration = newValue
                    objectWillChange.send()
                    videoCaptureDevice.unlockForConfiguration()
                } catch {
                    self.error = nil
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
        movieFileOutput.availableVideoCodecTypes.map {
            VideoOutputSettings.VideoCodec(type: $0)
        }
        #else
        VideoOutputSettings.VideoCodec.allCases
        #endif
    }
}

extension AVCaptureManager {
    func updateCaptureSession(videoDevice newVideoDevice: AVCaptureDevice?, audioDevice newAudioDevice: AVCaptureDevice?) {
        captureSession.beginConfiguration()
        
        do {
            if videoCaptureDevice != newVideoDevice {
                captureSession.inputs
                    .lazy
                    .compactMap {
                        $0 as? AVCaptureDeviceInput
                    }
                    .filter { [videoCaptureDevice] in $0.device.uniqueID == videoCaptureDevice?.uniqueID }
                    .forEach {
                        captureSession.removeInput($0)
                    }
            }

            if let newVideoDevice {
                try captureSession.addInput(AVCaptureDeviceInput(device: newVideoDevice))
            }
            
            if audioCaptureDevice != newAudioDevice {
                captureSession.inputs
                    .lazy
                    .compactMap {
                        $0 as? AVCaptureDeviceInput
                    }
                    .filter { [audioCaptureDevice] in $0.device.uniqueID == audioCaptureDevice?.uniqueID }
                    .forEach {
                        captureSession.removeInput($0)
                    }
            }
            
            if let newAudioDevice {
                try captureSession.addInput(AVCaptureDeviceInput(device: newAudioDevice))
            }
        } catch {
            self.error = error
        }

        objectWillChange.send()
        captureSession.commitConfiguration()
    }
}

extension AVCaptureManager {
    public var currentMovieFileOutputFileURL: URL? {
        movieFileOutput.outputFileURL
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
    private func updateVideoOutputSettings() {
        if let videoConnection = movieFileOutput.connection(with: .video) {
            movieFileOutput.setOutputSettings(nil, for: videoConnection)
            var outputSettings = movieFileOutput.outputSettings(for: videoConnection)

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
            for unsupportedOutputSettingsKey in Set(outputSettings.keys).subtracting(movieFileOutput.supportedOutputSettingsKeys(for: videoConnection)) {
                outputSettings.removeValue(forKey: unsupportedOutputSettingsKey)
            }
            #endif

            movieFileOutput.setOutputSettings(outputSettings, for: videoConnection)
        }
    }

    private func updateAudioOutputSettings() {
        if let audioConnection = movieFileOutput.connection(with: .audio) {
            movieFileOutput.setOutputSettings(nil, for: audioConnection)
            var outputSettings = movieFileOutput.outputSettings(for: audioConnection)

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
            for unsupportedOutputSettingsKey in Set(outputSettings.keys).subtracting(movieFileOutput.supportedOutputSettingsKeys(for: audioConnection)) {
                outputSettings.removeValue(forKey: unsupportedOutputSettingsKey)
            }
            #endif

            movieFileOutput.setOutputSettings(outputSettings, for: audioConnection)
        }
    }
}

extension AVCaptureManager {
    public func record() {
        movieFileOutput.stopRecording()

        let date = Date()

        guard let movieFileOutputFileURL = movieFileOutputFileURL(date: date) else {
            isMovieFileOutputRecording = false
            return
        }

        movieFileOutput.metadata = movieFileOutputMetadata(date: date)
        movieFileOutput.startRecording(to: movieFileOutputFileURL, recordingDelegate: self)
    }

    public func stopRecording() {
        movieFileOutput.stopRecording()
    }
}

extension AVCaptureManager: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        isMovieFileOutputRecording = true
    }

    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        defer {
            isMovieFileOutputRecording = false
        }

        if let error {
            self.error = error
        }
    }
}
