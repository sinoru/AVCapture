//
//  AVCaptureManager+MovieFileOutputAudioSettings.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/24.
//

import Foundation
import AVFoundation

extension AVCaptureManager {
    struct MovieFileOutputAudioSettings {
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
        
        var formatID: AudioFormatID = kAudioFormatMPEG4AAC
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
}

extension AVCaptureManager.MovieFileOutputAudioSettings.BitRateStrategy {
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

extension AVCaptureManager.MovieFileOutputAudioSettings.SampleRateConverterAlgorithm {
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
