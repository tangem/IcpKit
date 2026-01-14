//
//  Sequence+MapParallel.swift
//  IcpKit
//
//  Created by Konstantinos Gaitanis on 14.01.2026.
//
import Foundation

// MARK: Map Parallel
extension Sequence where Element: Sendable {
    func mapParallel<T>(
        isolation: isolated (any Actor)? = #isolation,
        transform: @Sendable @escaping (Element) async throws -> T
    ) async rethrows -> [T] where T : Sendable {
        try await withThrowingTaskGroup(isolation: isolation) { group in
            for item in self {
                group.addTask { try await transform(item) }
            }
            var results: [T] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    func compactMapParallel<T>(
        isolation: isolated (any Actor)? = #isolation,
        transform: @Sendable @escaping (Element) async throws -> T?
    ) async rethrows -> [T] where T : Sendable {
        try await mapParallel(isolation: isolation, transform: transform).compactMap { $0 }
    }
}
