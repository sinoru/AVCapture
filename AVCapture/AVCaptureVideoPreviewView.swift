//
//  AVCaptureVideoPreviewView.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/23.
//

import SwiftUI
import AVFoundation

struct AVCaptureVideoPreviewView: View {
    enum VideoGravity {
        case resize
        case resizeAspect
        case resizeAspectFill
    }
    
    let captureSession: AVCaptureSession
    let videoGravity: VideoGravity
}

extension AVCaptureVideoPreviewView.VideoGravity {
    var avLayerVideoGravity: AVLayerVideoGravity {
        switch self {
        case .resize:
            return .resize
        case .resizeAspect:
            return .resizeAspect
        case .resizeAspectFill:
            return .resizeAspectFill
        }
    }
}

#if os(macOS)
import AppKit

extension AVCaptureVideoPreviewView: NSViewRepresentable {
    class NSView: AppKit.NSView {
        var captureSession: AVCaptureSession {
            didSet {
                self.previewLayer?.session = captureSession
            }
        }
        var videoGravity: VideoGravity {
            didSet {
                self.previewLayer?.videoGravity = videoGravity.avLayerVideoGravity
            }
        }
        
        override var wantsLayer: Bool {
            get {
                true
            }
            set { }
        }
        
        private var previewLayer: AVCaptureVideoPreviewLayer? {
            self.layer as? AVCaptureVideoPreviewLayer
        }
        
        init(frame frameRect: NSRect, captureSession: AVCaptureSession, videoGravity: VideoGravity) {
            self.captureSession = captureSession
            self.videoGravity = videoGravity
            
            super.init(frame: frameRect)
            
            super.wantsLayer = true
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func makeBackingLayer() -> CALayer {
            let layer = AVCaptureVideoPreviewLayer(session: captureSession)
            layer.videoGravity = videoGravity.avLayerVideoGravity
            
            return layer
        }
    }
    
    typealias NSViewType = NSView
    
    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero, captureSession: captureSession, videoGravity: videoGravity)
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.captureSession = captureSession
        nsView.videoGravity = videoGravity
    }
}
#elseif os(iOS)
import UIKit

extension AVCaptureVideoPreviewView: UIViewRepresentable {
    class UIView: UIKit.UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var captureSession: AVCaptureSession {
            didSet {
                self.previewLayer?.session = captureSession
            }
        }
        var videoGravity: VideoGravity {
            didSet {
                self.previewLayer?.videoGravity = videoGravity.avLayerVideoGravity
            }
        }

        private var previewLayer: AVCaptureVideoPreviewLayer? {
            self.layer as? AVCaptureVideoPreviewLayer
        }

        init(frame: CGRect, captureSession: AVCaptureSession, videoGravity: VideoGravity) {
            self.captureSession = captureSession
            self.videoGravity = videoGravity

            super.init(frame: frame)

            self.previewLayer?.session = captureSession
            self.previewLayer?.videoGravity = videoGravity.avLayerVideoGravity
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    typealias UIViewType = UIView

    func makeUIView(context: Context) -> UIView {
        UIView(frame: .zero, captureSession: captureSession, videoGravity: videoGravity)
    }

    func updateUIView(_ nsView: UIView, context: Context) {
        nsView.captureSession = captureSession
        nsView.videoGravity = videoGravity
    }
}
#endif

struct AVCaptureVideoPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        AVCaptureVideoPreviewView(captureSession: AVCaptureSession(), videoGravity: .resize)
    }
}
