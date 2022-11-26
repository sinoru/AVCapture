//
//  ContentView.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/23.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif
import Foundation

struct ContentView: View {
    @StateObject var captureManager = AVCaptureManager()
    #if os(macOS)
    @State var previewingActivity: NSObjectProtocol?
    #endif
    
    var body: some View {
        VStack {
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
            
            AVFormView(captureManager: captureManager)
        }
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
        window.makeKeyAndOrderFront(nil)
    }
    #endif
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
