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
    
    var body: some View {
        AVFormView(captureManager: captureManager)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
