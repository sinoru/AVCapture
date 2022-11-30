//
//  Actor.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/27.
//

extension Actor {
    func run<T>(resultType: T.Type = T.self, body: @Sendable (isolated Self) async throws -> T) async rethrows -> T where T : Sendable {
        try await body(self)
    }
}
