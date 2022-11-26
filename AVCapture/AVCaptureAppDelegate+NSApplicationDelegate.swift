//
//  AVCaptureAppDelegate+NSApplicationDelegate.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/27.
//

#if os(macOS)

import AppKit

extension AVCaptureAppDelegate: NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

#endif
