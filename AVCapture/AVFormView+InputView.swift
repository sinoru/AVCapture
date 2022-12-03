//
//  AVFormView+InputView.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/25.
//

import SwiftUI
import AVFoundation
import AVCaptureKit

extension AVFormView {
    struct InputView: View {
        @ObservedObject var captureManager: AVCaptureManager

        @State var videoFrameRateRange: AVFrameRateRange?
        @FocusState var isFrameRateTextFieldFocused: Bool

        var body: some View {
            Section("Input Video") {
                Picker(
                    "Device",
                    selection: $captureManager.videoCaptureDevice
                ) {
                    Text("None")
                        .tag(AVCaptureDevice?.none)

                    ForEach(captureManager.availableVideoDevices) { device in
                        Text(device.localizedName)
                            .tag(device as AVCaptureDevice?)
                    }
                }

                Picker(
                    "Format",
                    selection: $captureManager.videoCaptureDeviceFormat
                ) {
                    if captureManager.videoCaptureDeviceFormat == nil || captureManager.videoCaptureDevice?.formats == nil {
                        Text("")
                            .tag(AVCaptureDevice.Format?.none)
                    }

                    ForEach(
                        captureManager.videoCaptureDevice?.formats ?? []
                    ) { format in
                        Text(format.localizedDescription)
                            .tag(format as AVCaptureDevice.Format?)
                    }
                }
                .disabled(captureManager.videoCaptureDevice == nil)
                .onChange(of: captureManager.videoCaptureDeviceFormat) { newValue in
                    videoFrameRateRange = captureManager.videoCaptureDeviceFormat?.videoSupportedFrameRateRanges.first
                }

                HStack {
                    Text("Frame Rate")

                    Spacer()

                    VStack {
                        HStack {
                            if let videoSupportedFrameRateRanges = captureManager.videoCaptureDeviceFormat?.videoSupportedFrameRateRanges, videoSupportedFrameRateRanges.count > 1 {
                                Picker("", selection: $videoFrameRateRange) {
                                    ForEach(videoSupportedFrameRateRanges) { videoFrameRateRange in
                                        Text("\(videoFrameRateRange.minFrameRate, specifier: "%.2f") - \(videoFrameRateRange.maxFrameRate, specifier: "%.2f")")
                                            .tag(videoFrameRateRange as AVFrameRateRange?)
                                    }
                                }
                            }

                            TextField("", value: $captureManager.videoCaptureDeviceFrameRate, format: .number)
                                .focused($isFrameRateTextFieldFocused)
                        }

                        Slider(
                            value: $captureManager.videoCaptureDeviceFrameRate,
                            in: (videoFrameRateRange?.minFrameRate ?? 0.0)...(videoFrameRateRange?.maxFrameRate ?? 1.0)
                        ) {
                            Text("")
                        } minimumValueLabel: {
                            if let minFrameRate = videoFrameRateRange?.minFrameRate {
                                Text(minFrameRate, format: .number)
                            }
                        } maximumValueLabel: {
                            if let maxFrameRate = videoFrameRateRange?.maxFrameRate {
                                Text(maxFrameRate, format: .number)
                            }
                        } onEditingChanged: { isEditing in
                            if isEditing {
                                isFrameRateTextFieldFocused = false
                            }
                        }
                        .disabled(videoFrameRateRange == nil)
                    }
                    .disabled(captureManager.videoCaptureDevice == nil)
                }
            }
            .onAppear {
                switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .authorized: // The user has previously granted access to the camera.
                    break

                case .notDetermined: // The user has not yet been asked for camera access.
                    break

                case .denied: // The user has previously denied access.
                    break

                case .restricted: // The user can't grant access due to restrictions.
                    break

                @unknown default:
                    break
                }
            }

            Section("Input Audio") {
                Picker(
                    "Device",
                    selection: $captureManager.audioCaptureDevice
                ) {
                    Text("None")
                        .tag(AVCaptureDevice?.none)

                    ForEach(captureManager.availableAudioDevices) { device in
                        Text(device.localizedName)
                            .tag(device as AVCaptureDevice?)
                    }
                }
            }
            .onAppear {
                switch AVCaptureDevice.authorizationStatus(for: .audio) {
                case .authorized: // The user has previously granted access to the camera.
                    break

                case .notDetermined: // The user has not yet been asked for camera access.
                    break

                case .denied: // The user has previously denied access.
                    break

                case .restricted: // The user can't grant access due to restrictions.
                    break

                @unknown default:
                    break
                }
            }
        }
    }
}

struct AVFormView_InputView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            AVFormView.InputView(captureManager: AVCaptureManager())
        }
    }
}
