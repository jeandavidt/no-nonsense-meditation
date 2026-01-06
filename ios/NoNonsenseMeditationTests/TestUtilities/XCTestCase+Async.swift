//
//  XCTestCase+Async.swift
//  NoNonsenseMeditationTests
//
//  Created on 2026-01-05.
//

import XCTest

/// Extension providing async testing utilities for XCTest
extension XCTestCase {

    /// Wait for an async condition to become true within a timeout
    /// - Parameters:
    ///   - timeout: Maximum time to wait in seconds
    ///   - description: Description for test failure
    ///   - condition: Async closure returning true when condition is met
    func waitForCondition(
        timeout: TimeInterval = 5.0,
        description: String = "Condition",
        condition: @escaping () async -> Bool
    ) async throws {
        let startTime = Date()

        while !await condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("\(description) did not become true within \(timeout) seconds")
                return
            }

            try await Task.sleep(for: .milliseconds(100))
        }
    }

    /// Create an expectation and wait for it with async/await
    /// - Parameters:
    ///   - description: Description of the expectation
    ///   - timeout: Timeout in seconds
    ///   - block: Async block to execute
    func asyncExpectation(
        description: String,
        timeout: TimeInterval = 5.0,
        block: @escaping () async throws -> Void
    ) async throws {
        let expectation = XCTestExpectation(description: description)

        Task {
            do {
                try await block()
                expectation.fulfill()
            } catch {
                XCTFail("Async block threw error: \(error)")
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: timeout)
    }

    /// Assert that an async operation completes within a timeout
    /// - Parameters:
    ///   - timeout: Maximum time allowed in seconds
    ///   - operation: Async operation to perform
    func assertCompletesWithin(
        _ timeout: TimeInterval,
        operation: @escaping () async throws -> Void
    ) async rethrows {
        let startTime = Date()

        try await operation()

        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(
            elapsed,
            timeout,
            "Operation took \(elapsed)s but should complete within \(timeout)s"
        )
    }

    /// Assert that two async values are equal
    /// - Parameters:
    ///   - expression1: First async expression
    ///   - expression2: Second async expression
    ///   - message: Optional message
    func assertAsyncEqual<T: Equatable>(
        _ expression1: @autoclosure () async throws -> T,
        _ expression2: @autoclosure () async throws -> T,
        _ message: String = ""
    ) async rethrows {
        let value1 = try await expression1()
        let value2 = try await expression2()

        XCTAssertEqual(value1, value2, message)
    }

    /// Assert that an async value is not nil
    /// - Parameters:
    ///   - expression: Async expression to evaluate
    ///   - message: Optional message
    func assertAsyncNotNil<T>(
        _ expression: @autoclosure () async throws -> T?,
        _ message: String = ""
    ) async rethrows {
        let value = try await expression()
        XCTAssertNotNil(value, message)
    }
}
