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
    
    let captureSession: AVCaptureSession = {
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
    
    private let captureMovieFileOutput = AVCaptureMovieFileOutput()
    
    private var anyCancellables: Set<AnyCancellable> = []
    
    @Published var videoCaptureDevice: AVCaptureDevice? {
        willSet {
            updateCaptureSession(videoDevice: newValue, audioDevice: audioCaptureDevice)
        }
    }
    
    @Published var audioCaptureDevice: AVCaptureDevice? {
        willSet {
            updateCaptureSession(videoDevice: videoCaptureDevice, audioDevice: newValue)
        }
    }
    
    @Published var movieFileVideoCodecType: AVVideoCodecType = .h264
    
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
    var availableVideoCodecTypes: [AVVideoCodecType] {
        #if os(iOS)
        captureMovieFileOutput.availableVideoCodecTypes
        #else
        [.h264, .hevc, .hevcWithAlpha, .jpeg, .proRes422, .proRes422LT, .proRes422HQ, .proRes422Proxy, .proRes4444, .proRes4444XQ]
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
//
//  AVCaptureManager.swift
//  AVCapture
//
//  Created by 강재홍 on 2022/11/23.
//

import Foundation
