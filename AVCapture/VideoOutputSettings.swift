//
//  VideoOutputSettings.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/25.
//

import Foundation
import AVKit

extension AVVideoCodecType {
    fileprivate static let proRes4444XQ: AVVideoCodecType = AVVideoCodecType(rawValue: FourCharCode(kCMVideoCodecType_AppleProRes4444XQ).description)
}

struct VideoOutputSettings {
    enum VideoCodec: Hashable, Sendable {
        case h264
        case hevc
        case hevcWithAlpha
        case jpeg
        case proRes422
        case proRes422LT
        case proRes422HQ
        case proRes422Proxy
        case proRes4444
        case proRes4444XQ
        case other(AVVideoCodecType)
    }

    var videoCodec: VideoCodec?
}

extension VideoOutputSettings.VideoCodec {
    var type: AVVideoCodecType {
        switch self {
        case .h264:
            return .h264
        case .hevc:
            return .hevc
        case .hevcWithAlpha:
            return .hevcWithAlpha
        case .jpeg:
            return .jpeg
        case .proRes422:
            return .proRes422
        case .proRes422LT:
            return .proRes422LT
        case .proRes422HQ:
            return .proRes422HQ
        case .proRes422Proxy:
            return .proRes422Proxy
        case .proRes4444:
            return .proRes4444
        case .proRes4444XQ:
            return .proRes4444XQ
        case .other(let videoCodecType):
            return videoCodecType
        }
    }

    init(type: AVVideoCodecType) {
        switch type {
        case .h264:
            self = .h264
        case .hevc:
            self = .hevc
        case .hevcWithAlpha:
            self = .hevcWithAlpha
        case .jpeg:
            self = .jpeg
        case .proRes422:
            self = .proRes422
        case .proRes422LT:
            self = .proRes422LT
        case .proRes422HQ:
            self = .proRes422HQ
        case .proRes422Proxy:
            self = .proRes422Proxy
        case .proRes4444:
            self = .proRes4444
        case .proRes4444XQ:
            self = .proRes4444XQ
        default:
            self = .other(type)
        }
    }
}

extension VideoOutputSettings.VideoCodec {
    var name: String {
        switch self {
        case .h264:
            return "H.264"
        case .hevc:
            return "HEVC"
        case .hevcWithAlpha:
            return "HEVC with alpha"
        case .jpeg:
            return "JPEG"
        case .proRes422:
            return "Apple ProRes 422"
        case .proRes422LT:
            return "Apple ProRes 422 LT"
        case .proRes422HQ:
            return "Apple ProRes 422 HQ"
        case .proRes422Proxy:
            return "Apple ProRes 422 Proxy"
        case .proRes4444:
            return "Apple ProRes 4444"
        case .proRes4444XQ:
            return "Apple ProRes 4444 XQ"
        case .other(let videoCodecType):
            return videoCodecType.rawValue
        }
    }
}

extension VideoOutputSettings.VideoCodec: Identifiable {
    var id: some Hashable {
        self.type
    }
}

extension VideoOutputSettings.VideoCodec: RawRepresentable {
    typealias RawValue = AVVideoCodecType

    var rawValue: AVVideoCodecType {
        self.type
    }

    init(rawValue: AVVideoCodecType) {
        self.init(type: rawValue)
    }
}

extension VideoOutputSettings.VideoCodec: CaseIterable {
    static var allCases: [VideoOutputSettings.VideoCodec] {
        [.h264, .hevc, .hevcWithAlpha, .jpeg, .proRes422, .proRes422LT, .proRes422HQ, .proRes422Proxy, .proRes4444, .proRes4444XQ]
    }
}
