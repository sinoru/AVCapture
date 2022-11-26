//
//  AudioOutputDeviceManager.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/25.
//

#if os(macOS)

import Foundation
import CoreAudio

actor AudioOutputDeviceManager: ObservableObject {
    private static let audioObjectSystemObject = AudioObjectID(kAudioObjectSystemObject)
    
    private var audioObjectPropertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeOutput,
        mElement: kAudioObjectPropertyElementWildcard
    )
    
    private lazy nonisolated var dispatchQueue = DispatchQueue(
        label: String(reflecting: self),
        qos: .default,
        autoreleaseFrequency: .workItem
    )

    private lazy nonisolated var listnerBlock: @convention(block) (UInt32, UnsafePointer<AudioObjectPropertyAddress>) -> Void = { [weak self] status, inAddresses in
        guard let self = self else { return }

        Task {
            await self.run { `self` in
                await self.fetchDevices()
            }
        }
    }

    @MainActor @Published var audioDevices: [AudioDevice] = []

    init() {
        Task {
            await run { `self` in
                AudioObjectAddPropertyListenerBlock(Self.audioObjectSystemObject, &self.audioObjectPropertyAddress, dispatchQueue, self.listnerBlock)

                await self.fetchDevices()
            }
        }
    }
    
    deinit {
        AudioObjectRemovePropertyListenerBlock(Self.audioObjectSystemObject, &self.audioObjectPropertyAddress, dispatchQueue, self.listnerBlock)
    }
    
    private func fetchDevices() async {
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
        
        await MainActor.run { [devicesList] in
            self.audioDevices = devicesList.map {
                AudioDevice(id: $0)
            }
        }
    }
}

#endif
