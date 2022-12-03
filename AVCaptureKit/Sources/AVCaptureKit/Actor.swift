//
//  Actor.swift
//  AVCapture
//
//  Created by Jaehong Kang on 2022/11/27.
//

extension Actor {
    public func run<T>(resultType: T.Type = T.self, body: @Sendable (isolated Self) throws -> T) async rethrows -> T where T : Sendable {
        try body(self)
    }

    @_disfavoredOverload
    public func run<T>(resultType: T.Type = T.self, body: @Sendable (isolated Self) async throws -> T) async rethrows -> T where T : Sendable {
        try await body(self)
    }
}

extension MainActor {
    @_disfavoredOverload
    public static func run<T>(resultType: T.Type = T.self, body: @MainActor @Sendable () async throws -> T) async rethrows -> T where T : Sendable {
        try await body()
    }
}
