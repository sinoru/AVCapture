//
//  AVFormView.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/23.
//

import SwiftUI
import AVCaptureKit

struct AVFormView: View {
    @ObservedObject var captureManager: AVCaptureManager
    
    #if os(macOS)
    @StateObject var audioOutputDeviceManager = AudioOutputDeviceManager()
    @State var previewingActivity: NSObjectProtocol?
    #endif
    
    @State var isErrorPresented: Bool = false

    var body: some View {
        Form {
            InputView(captureManager: captureManager)

            Section("Preview") {
                if let videoCaptureDeviceFormat = captureManager.videoCaptureDeviceFormat {
                    AVCaptureVideoPreviewView(captureSession: captureManager.captureSession, videoGravity: .resizeAspectFill)
                        .frame(
                            maxWidth: CGFloat(videoCaptureDeviceFormat.formatDescription.dimensions.width),
                            maxHeight: CGFloat(videoCaptureDeviceFormat.formatDescription.dimensions.height)
                        )
                        .aspectRatio(
                            CGFloat(videoCaptureDeviceFormat.formatDescription.dimensions.width) / CGFloat(videoCaptureDeviceFormat.formatDescription.dimensions.height),
                            contentMode: .fit
                        )
                        #if os(macOS)
                        .contextMenu {
                            Button("Open in new window", action: openPreviewWindow)
                        }
                        .onAppear {
                            guard self.previewingActivity == nil else {
                                return
                            }

                            self.previewingActivity = ProcessInfo.processInfo.beginActivity(
                                options: [.idleSystemSleepDisabled, .automaticTerminationDisabled, .trackingEnabled],
                                reason: "Previewing"
                            )
                        }
                        .onDisappear {
                            guard let previewingActivity else {
                                return
                            }

                            ProcessInfo.processInfo.endActivity(previewingActivity)
                            self.previewingActivity = nil
                        }
                        #endif
                }

                #if os(macOS)
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
                #endif
            }

            OutputView(captureManager: captureManager)

            Section {
                if !captureManager.isMovieFileOutputRecording {
                    Button("Record", action: record)
                } else {
                    Button("Stop", action: stop)
                }
            } header: {
                Text("")
            } footer: {
                if
                    captureManager.isMovieFileOutputRecording,
                    let currentMovieFileOutputFileURL = captureManager.currentMovieFileOutputFileURL
                {
                    Text("Recording to \(currentMovieFileOutputFileURL)")
                }
            }
            .onDisappear(perform: stop)
        }
        .formStyle(.grouped)
        .alert("Error", isPresented: $isErrorPresented, presenting: captureManager.error) { _ in
            
        } message: {
            Text($0.localizedDescription)
        }
        .onReceive(captureManager.$error) { _ in
            if captureManager.error != nil {
                isErrorPresented = true
            }
        }
        .padding()
    }

    #if os(macOS)
    private func openPreviewWindow() {
        guard let videoCaptureDeviceFormat = captureManager.videoCaptureDeviceFormat else {
            return
        }

        let videoSize = CGSize(
            width: CGFloat(videoCaptureDeviceFormat.formatDescription.dimensions.width),
            height: CGFloat(videoCaptureDeviceFormat.formatDescription.dimensions.height)
        )

        let hostingController = NSHostingController(
            rootView: AVCaptureVideoPreviewView(captureSession: captureManager.captureSession, videoGravity: .resizeAspectFill)
                .frame(
                    idealWidth: videoSize.width,
                    idealHeight: videoSize.height
                )
                .ignoresSafeArea(.all, edges: .all)
        )
        hostingController.view.frame.size = videoSize

        let window = NSWindow(contentViewController: hostingController)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.contentAspectRatio = videoSize
        window.isMovableByWindowBackground = true
        window.title = String(localized: "\(Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String ?? "") Preview")
        window.makeKeyAndOrderFront(nil)
    }
    #endif

    func record() {
        Task {
            await captureManager.record()
        }
    }

    func stop() {
        Task {
            await captureManager.stopRecording()
        }
    }
}

struct AVFormView_Previews: PreviewProvider {
    static var previews: some View {
        AVFormView(captureManager: AVCaptureManager())
    }
}
