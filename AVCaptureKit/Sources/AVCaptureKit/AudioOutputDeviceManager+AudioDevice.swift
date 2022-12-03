//
//  AudioOutputDeviceManager+AudioDevice.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/25.
//

#if os(macOS)

import Foundation
import CoreAudio

extension AudioOutputDeviceManager {
    public struct AudioDevice: Equatable, Hashable, Identifiable, Sendable {
        public let id: AudioDeviceID
        
        public init(id: AudioDeviceID) {
            self.id = id
        }
        
        public var name: String? {
            var propertyAddress = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertyName,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            
            var name: CFString?
            var size = UInt32(MemoryLayout<CFString>.size)
            
            AudioObjectGetPropertyData(
                id,
                &propertyAddress,
                0,
                nil,
                &size,
                &name
            )
            
            return name as String?
        }
        
        public var uniqueID: String? {
            var propertyAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceUID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            
            var name: CFString?
            var size = UInt32(MemoryLayout<CFString>.size)
            
            AudioObjectGetPropertyData(
                id,
                &propertyAddress,
                0,
                nil,
                &size,
                &name
            )
            
            return name as String?
        }
    }
}

#endif
