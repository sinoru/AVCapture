//
//  AVCaptureManager+CaptureSessionActor.swift
//  
//
//  Created by Jaehong Kang on 2022/12/14.
//

import Foundation
import AVFoundation

extension AVCaptureManager {
    actor CaptureSessionActor {
        nonisolated let _captureSession = AVCaptureSession()
        nonisolated let _movieFileOutput = AVCaptureMovieFileOutput()
    }
}

extension AVCaptureManager.CaptureSessionActor {
    var captureSession: AVCaptureSession {
        _captureSession
    }

    var movieFileOutput: AVCaptureMovieFileOutput {
        _movieFileOutput
    }

    func initializeCaptureSession() {
        configureSession { captureSession in
            #if os(iOS)
            if captureSession.isMultitaskingCameraAccessSupported {
                // Enable using the camera in multitasking modes.
                captureSession.isMultitaskingCameraAccessEnabled = true
            }
            #endif

            captureSession.addOutput(_movieFileOutput)
        }

        captureSession.startRunning()
    }

    func configureSession(configuration: (AVCaptureSession) throws -> Void) rethrows {
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
        }

        try configuration(captureSession)
    }

    func updateDevice(oldDevice: AVCaptureDevice?, newDevice: AVCaptureDevice?) throws {
        guard oldDevice != newDevice else {
            return
        }

        try configureSession { captureSession in
            if oldDevice != newDevice {
                captureSession.inputs
                    .lazy
                    .compactMap {
                        $0 as? AVCaptureDeviceInput
                    }
                    .filter { $0.device.uniqueID == oldDevice?.uniqueID }
                    .forEach {
                        captureSession.removeInput($0)
                    }
            }

            if let newDevice {
                try captureSession.addInput(AVCaptureDeviceInput(device: newDevice))
            }
        }
    }
}
