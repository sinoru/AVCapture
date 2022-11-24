//
//  AVFormView.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/23.
//

import SwiftUI
import AVFoundation

struct AVFormView: View {
    @ObservedObject var captureManager: AVCaptureManager
    
    #if os(macOS)
    @StateObject var audioOutputDeviceManager = AudioOutputDeviceManager()
    #endif
    
    @State var videoFrameRateRange: AVFrameRateRange?
    @FocusState var isFrameRateTextFieldFocused: Bool
    
    @State var isErrorPresented: Bool = false

    var body: some View {
        Form {
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
                            Picker("", selection: $videoFrameRateRange) {
                                if let videoSupportedFrameRateRanges = captureManager.videoCaptureDeviceFormat?.videoSupportedFrameRateRanges {
                                    ForEach(videoSupportedFrameRateRanges) { videoFrameRateRange in
                                        Text("\(videoFrameRateRange.minFrameRate, specifier: "%.2f") - \(videoFrameRateRange.maxFrameRate, specifier: "%.2f")")
                                            .tag(videoFrameRateRange as AVFrameRateRange?)
                                    }
                                } else {
                                    Text("")
                                        .tag(AVFrameRateRange?.none)
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
            
            #if os(macOS)
            Section("Preview") {
                Toggle("Audio Preview", isOn: $captureManager.isAudioPreviewing)
                
                Picker(
                    "Audio Preview Device",
                    selection: $captureManager.audioPreviewOutputDeviceUniqueID
                ) {
                    Text("Default")
                        .tag(String?.none)
                    
                    ForEach(audioOutputDeviceManager.audioDevices) { audioDevice in
                        Text(audioDevice.name ?? "Unknown")
                            .tag(audioDevice.uniqueID)
                    }
                }
                
                Slider(
                    value: $captureManager.audioPreviewOutputVolume,
                    in: 0.0...1.0
                ) {
                    Text("Audio Preview Volume")
                }
            }
            #endif
            
            Section("Output") {
                Picker(
                    "Video Codec",
                    selection: $captureManager.movieFileVideoCodecType
                ) {
                    ForEach(captureManager.availableVideoCodecTypes) { videoCodecType in
                        Group {
                            switch videoCodecType {
                            case .h264:
                                Text("H.264")
                            case .hevc:
                                Text("HEVC")
                            case .hevcWithAlpha:
                                Text("HEVC with alpha")
                            case .jpeg:
                                Text("JPEG")
                            case .proRes422:
                                Text("Apple ProRes 422")
                            case .proRes422LT:
                                Text("Apple ProRes 422 LT")
                            case .proRes422HQ:
                                Text("Apple ProRes 422 HQ")
                            case .proRes422Proxy:
                                Text("Apple ProRes 422 Proxy")
                            case .proRes4444:
                                Text("Apple ProRes 4444")
                            case .proRes4444XQ:
                                Text("Apple ProRes 4444 XQ")
                            default:
                                Text(videoCodecType.rawValue)
                            }
                        }
                        .tag(videoCodecType)
                    }
                }
                
                
                Button("Record", action: record)
            }
        }
        .formStyle(.grouped)
        .alert("Error", isPresented: $isErrorPresented, presenting: captureManager.error) { _ in
            
        } message: {
            Text($0.localizedDescription)
        }
        .padding()
    }

    func record() {
        
    }
}

struct AVFormView_Previews: PreviewProvider {
    static var previews: some View {
        AVFormView(captureManager: AVCaptureManager())
    }
}
