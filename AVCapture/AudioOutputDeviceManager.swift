//
//  AudioOutputDeviceManager.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/25.
//

#if os(macOS)

import Foundation
import CoreAudio

class AudioOutputDeviceManager: ObservableObject {
    private static let audioObjectSystemObject = AudioObjectID(kAudioObjectSystemObject)
    
    private var audioObjectPropertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeOutput,
        mElement: kAudioObjectPropertyElementWildcard
    )
    
    private lazy var dispatchQueue = DispatchQueue(
        label: String(reflecting: self),
        qos: .default,
        autoreleaseFrequency: .workItem
    )
    
    private lazy var listnerBlock: AudioObjectPropertyListenerBlock = { [weak self] status, inAddresses in
        guard let self = self else { return }
        
        self.fetchDevices()
    }
    
    @Published var audioDevices: [AudioDevice] = []
    
    init() {
        AudioObjectAddPropertyListenerBlock(Self.audioObjectSystemObject, &audioObjectPropertyAddress, dispatchQueue, listnerBlock)
        
        fetchDevices()
    }
    
    deinit {
        AudioObjectRemovePropertyListenerBlock(Self.audioObjectSystemObject, &audioObjectPropertyAddress, dispatchQueue, listnerBlock)
    }
    
    private func fetchDevices() {
        var devicesListPropertySize: UInt32 = 0
        
        let getPropertyDataSizeStatus = AudioObjectGetPropertyDataSize(
            Self.audioObjectSystemObject,
            &audioObjectPropertyAddress,
            0,
            nil,
            &devicesListPropertySize
        )
        
        guard getPropertyDataSizeStatus == noErr else {
            return
        }
        
        
        var devicesList: [AudioDeviceID] = .init(
            repeating: kAudioObjectUnknown,
            count: Int(devicesListPropertySize) / MemoryLayout<AudioDeviceID>.size
        )
        
        let getPropertyDataStatus = AudioObjectGetPropertyData(
            Self.audioObjectSystemObject,
            &audioObjectPropertyAddress,
            0,
            nil,
            &devicesListPropertySize,
            &devicesList
        )
        
        guard getPropertyDataStatus == noErr else {
            return
        }
        
        self.audioDevices = devicesList.map {
            AudioDevice(id: $0)
        }
    }
}

#endif
