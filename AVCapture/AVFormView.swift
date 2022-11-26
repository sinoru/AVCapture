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
    
    @State var isErrorPresented: Bool = false

    var body: some View {
        Form {
            InputView(captureManager: captureManager)

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
            
            OutputView(captureManager: captureManager)

            Section("") {
                if !captureManager.isMovieFileOutputRecording {
                    Button("Record", action: record)
                } else {
                    Button("Stop", action: stop)
                }
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
        captureManager.record()
    }

    func stop() {
        captureManager.stopRecording()
    }
}

struct AVFormView_Previews: PreviewProvider {
    static var previews: some View {
        AVFormView(captureManager: AVCaptureManager())
    }
}
