//
//  ContentView.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/23.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject var captureManager = AVCaptureManager()
    
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
                .ignoresSafeArea(.all, edges: .all)
                .frame(
                    idealWidth: videoSize.width,
                    idealHeight: videoSize.height
                )
                .aspectRatio(
                    videoSize.width / videoSize.height,
                    contentMode: .fit
                )
        )
        hostingController.view.frame.size = videoSize
        
        let window = NSWindow(contentViewController: hostingController)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .automatic
        window.styleMask.insert(.fullSizeContentView)
        window.aspectRatio = videoSize
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
