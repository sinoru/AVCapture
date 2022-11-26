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
    private let discoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInMicrophone, .deskViewCamera, .externalUnknown],
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

        captureSession.commitConfiguration()
        
        return captureSession
    }()

    private var anyCancellables: Set<AnyCancellable> = []

    private var videoCaptureDeviceAnyCancellables: Set<AnyCancellable> = []
    
    @Published var videoCaptureDevice: AVCaptureDevice? {
        willSet {
            videoCaptureDeviceAnyCancellables = []

            updateCaptureSession(videoDevice: newValue, audioDevice: audioCaptureDevice)
        }
        didSet {
            videoCaptureDevice?
                .publisher(for: \.formats)
                .sink { [objectWillChange] _ in
                    objectWillChange.send()
                }
                .store(in: &videoCaptureDeviceAnyCancellables)
        }
    }
    
    @Published var audioCaptureDevice: AVCaptureDevice? {
        willSet {
            updateCaptureSession(videoDevice: videoCaptureDevice, audioDevice: newValue)
        }
    }
    
    #if os(macOS)
    private let audioPreviewOutput = AVCaptureAudioPreviewOutput()
    
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
    
    @Published var movieFileVideoOutputSettings = VideoOutputSettings()
    @Published var movieFileAudioOutputSettings = AudioOutputSettings()
    
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
                    objectWillChange.send()
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
                    objectWillChange.send()
                    videoCaptureDevice.activeVideoMinFrameDuration = newValue
                    videoCaptureDevice.activeVideoMaxFrameDuration = newValue
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

extension AVCaptureManager {
    var availableVideoCodecs: [VideoOutputSettings.VideoCodec] {
        #if os(iOS)
        captureMovieFileOutput.availableVideoCodecTypes.map {
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
        
        captureSession.commitConfiguration()
    }
}
