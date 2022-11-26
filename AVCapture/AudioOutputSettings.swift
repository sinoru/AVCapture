//
//  AudioOutputSettings.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/24.
//

import Foundation
import AVFoundation

struct AudioOutputSettings {
    enum AudioFormat: Hashable, Sendable {
        case linearPCM
        case mpeg4AAC
        case appleLossless
        case other(AudioFormatID)
    }
    
    enum BitRateStrategy {
        case constant
        case longTermAverage
        case variableConstrained
        case variable
    }
    
    enum SampleRateConverterAlgorithm {
        case normal
        case mastering
        case minimumPhase
    }

    var format: AudioFormat?
    var sampleRate: Float?
    var numberOfChannels: Int?

    var linearPCMBitDepth: Int?
    var linearPCMIsBigEdian: Bool?
    var linearPCMIsFloat: Bool?

    var encoderAudioQuality: AVAudioQuality?
    var encoderAudioQualityForVBR: AVAudioQuality?
    
    var encoderBitRate: Int?
    var encoderBitRatePerChannel: Int?
    var encoderBitRateStrategy: BitRateStrategy?
    var encoderBitDepthHint: Int?
    
    var sampleRateConverterAlgorithm: SampleRateConverterAlgorithm?
}

extension AudioOutputSettings.AudioFormat {
    init(id: AudioFormatID) {
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
    
    var id: AudioFormatID {
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
    var name: String {
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
    typealias RawValue = AudioFormatID
    
    init(rawValue: AudioFormatID) {
        self.init(id: rawValue)
    }
    
    var rawValue: AudioFormatID {
        self.id
    }
}

extension AudioOutputSettings.AudioFormat: Identifiable { }

extension AudioOutputSettings.AudioFormat: CaseIterable {
    static var allCases: [AudioOutputSettings.AudioFormat] {
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
