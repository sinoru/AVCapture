//
//  AudioOutputDeviceManager.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/25.
//

#if os(macOS)

import Foundation
import CoreAudio

public actor AudioOutputDeviceManager: ObservableObject {
    private static let audioObjectSystemObject = AudioObjectID(kAudioObjectSystemObject)
    
    private nonisolated let audioObjectPropertyAddress = AudioObjectPropertyAddress(
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
            await self.fetchDevices()
        }
    }

    @MainActor @Published
    public var audioDevices: [AudioDevice] = []

    public init() {
        _ = listnerBlock

        Task {
            await run { `self` in
                _ = withUnsafePointer(to: audioObjectPropertyAddress) { audioObjectPropertyAddress in
                    AudioObjectAddPropertyListenerBlock(Self.audioObjectSystemObject, audioObjectPropertyAddress, dispatchQueue, self.listnerBlock)
                }

                await self.fetchDevices()
            }
        }
    }

    deinit {
        _ = withUnsafePointer(to: audioObjectPropertyAddress) { audioObjectPropertyAddress in
            AudioObjectRemovePropertyListenerBlock(Self.audioObjectSystemObject, audioObjectPropertyAddress, dispatchQueue, self.listnerBlock)
        }
    }

    private func fetchDevices() async {
        let devicesList: [AudioDeviceID]? = withUnsafePointer(to: audioObjectPropertyAddress) { audioObjectPropertyAddress in
            var devicesListPropertySize: UInt32 = 0

            let getPropertyDataSizeStatus = AudioObjectGetPropertyDataSize(
                Self.audioObjectSystemObject,
                audioObjectPropertyAddress,
                0,
                nil,
                &devicesListPropertySize
            )

            guard getPropertyDataSizeStatus == noErr else {
                return nil
            }

            var devicesList: [AudioDeviceID] = .init(
                repeating: kAudioObjectUnknown,
                count: Int(devicesListPropertySize) / MemoryLayout<AudioDeviceID>.size
            )

            let getPropertyDataStatus = AudioObjectGetPropertyData(
                Self.audioObjectSystemObject,
                audioObjectPropertyAddress,
                0,
                nil,
                &devicesListPropertySize,
                &devicesList
            )

            guard getPropertyDataStatus == noErr else {
                return nil
            }

            return devicesList
        }

        guard let devicesList else {
            return
        }

        await MainActor.run {
            self.audioDevices = devicesList.map {
                AudioDevice(id: $0)
            }
        }
    }
}

#endif
