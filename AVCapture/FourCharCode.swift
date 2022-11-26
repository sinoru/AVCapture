//
//  FourCharCode.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/23.
//

import Foundation

struct FourCharCode {
    let value: Foundation.FourCharCode
    
    init(_ stringValue: String) {
        var value: Foundation.FourCharCode = 0
        
        stringValue.utf8.prefix(4).forEach { byte in
            value = value << 8 + Foundation.FourCharCode(byte)
        }
        
        self.value = value
    }
    
    init(_ value: IntegerLiteralType) {
        self.value = value
    }
}

extension FourCharCode: RawRepresentable {
    typealias RawValue = Foundation.FourCharCode
    
    var rawValue: RawValue {
        value
    }
    
    init(rawValue value: IntegerLiteralType) {
        self.init(value)
    }
}

extension FourCharCode: ExpressibleByIntegerLiteral {
    typealias IntegerLiteralType = Foundation.FourCharCode
    
    init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}

extension FourCharCode: ExpressibleByStringLiteral {
    typealias StringLiteralType = String
    
    init(stringLiteral stringValue: String) {
        self.init(stringValue)
    }
}

extension FourCharCode: LosslessStringConvertible {
    var description: String {
        let cString: [CChar] = [
            CChar(value >> 24 & 0xFF),
            CChar(value >> 16 & 0xFF),
            CChar(value >> 8 & 0xFF),
            CChar(value & 0xFF),
            0
        ]
        
        return String(cString: cString)
    }
}
