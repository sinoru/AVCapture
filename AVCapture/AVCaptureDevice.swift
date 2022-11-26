//
//  AVCaptureDevice.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/23.
//

import Foundation
import Combine
import AVFoundation

extension AVCaptureDevice: Identifiable {
    public var id: some Hashable {
        self.uniqueID
    }
}

extension AVCaptureDevice.Format: Identifiable {
    public var localizedDescription: String {
        let description = String(describing: self)
        
        return (description.wholeMatch(of: /<(.+)> (.*)/)?.2).flatMap { String($0) } ?? description
    }
}

extension AVFrameRateRange: Identifiable {
    
}
