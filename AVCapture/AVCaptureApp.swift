//
//  AVCaptureApp.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/23.
//

import SwiftUI

@main
struct AVCaptureApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AVCaptureAppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
