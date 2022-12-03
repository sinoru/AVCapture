//
//  AudioOutputSettings.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/24.
//

import Foundation
import AVFoundation

public struct AudioOutputSettings {
    public enum AudioFormat: Hashable, Sendable {
        case linearPCM
        case mpeg4AAC
        case appleLossless
        case other(AudioFormatID)
    }
    
    public enum BitRateStrategy {
        case constant
        case longTermAverage
        case variableConstrained
        case variable
    }
    
    public enum SampleRateConverterAlgorithm {
        case normal
        case mastering
        case minimumPhase
    }

    public var format: AudioFormat?
    public var sampleRate: Float?
    public var numberOfChannels: Int?

    public var linearPCMBitDepth: Int?
    public var linearPCMIsBigEdian: Bool?
    public var linearPCMIsFloat: Bool?

    public var encoderAudioQuality: AVAudioQuality?
    public var encoderAudioQualityForVBR: AVAudioQuality?
    
    public var encoderBitRate: Int?
    public var encoderBitRatePerChannel: Int?
    public var encoderBitRateStrategy: BitRateStrategy?
    public var encoderBitDepthHint: Int?
    
    public var sampleRateConverterAlgorithm: SampleRateConverterAlgorithm?
}

extension AudioOutputSettings.AudioFormat {
    public init(id: AudioFormatID) {
        switch id {
        case kAudioFormatLinearPCM:
            self = .linearPCM
        case kAudioFormatMPEG4AAC:
            self = .mpeg4AAC
        case kAudioFormatAppleLossless:
            self = .appleLossless
        default:
            self = .other(id)
        }
    }
    
    public var id: AudioFormatID {
        switch self {
        case .linearPCM:
            return kAudioFormatLinearPCM
        case .mpeg4AAC:
            return kAudioFormatMPEG4AAC
        case .appleLossless:
            return kAudioFormatAppleLossless
        case .other(let audioFormatID):
            return audioFormatID
        }
    }
}

extension AudioOutputSettings.AudioFormat {
    public var name: String {
        switch self {
        case .linearPCM:
            return "Linear PCM"
        case .mpeg4AAC:
            return "MPEG-4 AAC"
        case .appleLossless:
            return "Apple Lossless"
        case .other(let audioFormatID):
            return FourCharCode(audioFormatID).description
        }
    }
}

extension AudioOutputSettings.AudioFormat: RawRepresentable {
    public typealias RawValue = AudioFormatID
    
    public init(rawValue: AudioFormatID) {
        self.init(id: rawValue)
    }
    
    public var rawValue: AudioFormatID {
        self.id
    }
}

extension AudioOutputSettings.AudioFormat: Identifiable { }

extension AudioOutputSettings.AudioFormat: CaseIterable {
    public static var allCases: [AudioOutputSettings.AudioFormat] {
        [.linearPCM, .mpeg4AAC, .appleLossless]
    }
}

extension AudioOutputSettings.BitRateStrategy {
    var avAudioBitRateStrategy: String {
        switch self {
        case .constant:
            return AVAudioBitRateStrategy_Constant
        case .longTermAverage:
            return AVAudioBitRateStrategy_LongTermAverage
        case .variableConstrained:
            return AVAudioBitRateStrategy_VariableConstrained
        case .variable:
            return AVAudioBitRateStrategy_Variable
        }
    }
}

extension AudioOutputSettings.SampleRateConverterAlgorithm {
    var avSampleRateConverterAlgorithm: String {
        switch self {
        case .normal:
            return AVSampleRateConverterAlgorithm_Normal
        case .mastering:
            return AVSampleRateConverterAlgorithm_Mastering
        case .minimumPhase:
            return AVSampleRateConverterAlgorithm_MinimumPhase
        }
    }
}
