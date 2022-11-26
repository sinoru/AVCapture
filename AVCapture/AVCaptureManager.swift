//
//  AVCaptureManager.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/23.
//

import Foundation
import AVFoundation
import Combine

class AVCaptureManager: NSObject, ObservableObject {
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
    
    private(set) lazy var captureSession: AVCaptureSession = {
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
    
    @Published var videoCaptureDevice: AVCaptureDevice? {
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
    
    @Published var audioCaptureDevice: AVCaptureDevice? {
        willSet {
            updateCaptureSession(videoDevice: videoCaptureDevice, audioDevice: newValue)
        }
    }
    
    #if os(macOS)
    private let audioPreviewOutput = AVCaptureAudioPreviewOutput()
    
    @Published var isAudioPreviewing: Bool = false {
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

    #if os(iOS)
    var movieFileOutputDestinationURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    #else
    @Published var movieFileOutputDestinationURL: URL? = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first?.resolvingSymlinksInPath() ?? URL(filePath: NSHomeDirectory())
    #endif

    @Published var movieFileOutputFilenameFormat: String = "AVCapture %yyyy-%MM-%dd %HH.%mm.%ss"

    private let movieFileOutput = AVCaptureMovieFileOutput()
    @Published var movieFileVideoOutputSettings = VideoOutputSettings() {
        didSet {
            updateVideoOutputSettings()
        }
    }
    @Published var movieFileAudioOutputSettings = AudioOutputSettings() {
        didSet {
            updateAudioOutputSettings()
        }
    }

    @Published var isMovieFileOutputRecording: Bool = false
    
    @Published var error: Error?
    
    override init() {
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
    var availableDevices: [AVCaptureDevice] {
        discoverySession.devices
    }
    
    var availableVideoDevices: [AVCaptureDevice] {
        availableDevices.filter {
            $0.hasMediaType(.video)
        }
    }
    
    var availableAudioDevices: [AVCaptureDevice] {
        availableDevices.filter {
            $0.hasMediaType(.audio)
        }
    }
}

extension AVCaptureManager {
    var videoCaptureDeviceFormats: [AVCaptureDevice.Format]? {
        videoCaptureDevice?.formats
    }

    var videoCaptureDeviceFormat: AVCaptureDevice.Format? {
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
    var videoCaptureDeviceFrameDuration: CMTime? {
        get {
            videoCaptureDevice?.activeVideoMaxFrameDuration
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
    
    var videoCaptureDeviceFrameRate: Float64 {
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
    var audioPreviewOutputDeviceUniqueID: String? {
        get {
            audioPreviewOutput.outputDeviceUniqueID
        }
        set {
            objectWillChange.send()
            audioPreviewOutput.outputDeviceUniqueID = newValue
        }
    }

    var audioPreviewOutputVolume: Float {
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
    var availableVideoCodecs: [VideoOutputSettings.VideoCodec] {
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

        updateVideoOutputSettings()
        updateAudioOutputSettings()

        objectWillChange.send()
        captureSession.commitConfiguration()
    }
}

extension AVCaptureManager {
    func movieFileOutputFileURL(date: Date = Date()) -> URL? {
        guard let movieFileOutputDestinationURL else {
            return nil
        }

        let dateFormatter = DateFormatter()
        let date = Date()

        let filename = movieFileOutputFilenameFormat
            .replacing(/%(\w+)/) { match in
                dateFormatter.dateFormat = String(match.1)

                return dateFormatter.string(from: date)
            }

        return movieFileOutputDestinationURL.appendingPathComponent(filename, conformingTo: UTType.quickTimeMovie)
    }

    func movieFileOutputMetadata(date: Date = Date()) -> [AVMetadataItem] {
        var metadata: [AVMetadataItem] = [
            AVMutableMetadataItem(identifier: .commonIdentifierCreationDate, value: date as NSDate )
        ].compactMap { $0 }

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
    func record() {
        let date = Date()

        guard let movieFileOutputFileURL = movieFileOutputFileURL(date: date) else {
            return
        }

        movieFileOutput.metadata = movieFileOutputMetadata(date: date)

        isMovieFileOutputRecording = true
        movieFileOutput.startRecording(to: movieFileOutputFileURL, recordingDelegate: self)
    }

    func stopRecording() {
        movieFileOutput.stopRecording()
    }
}

extension AVCaptureManager: AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error {
            self.error = error
        }

        captureSession.removeOutput(output)

        isMovieFileOutputRecording = false
    }
}
