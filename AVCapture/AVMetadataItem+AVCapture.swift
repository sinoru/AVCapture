//
//  AVMetadataItem+AVCapture.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/26.
//

import AVFoundation

extension AVMutableMetadataItem {
    convenience init(identifier: AVMetadataIdentifier?, value: (NSCopying & NSObjectProtocol)?) {
        self.init()

        self.identifier = identifier
        self.value = value
    }
}
