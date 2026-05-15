//
//  CheckoutPendingOperationsTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 5/7/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

@MainActor
final class CheckoutPendingOperationsTests: XCTestCase {

    func testEnqueueSessionUpdateSerializesOperationsAndKeepsLoadingUntilDrained() async throws {
        let checkout = makeCheckoutWithOpenSession()
        let firstGate = CheckoutPendingOperationsTestGate()
        var events: [String] = []

        let firstTask = Task { @MainActor in
            try await checkout.enqueueSessionUpdate {
                events.append("first started")
                await firstGate.wait()
                events.append("first finished")
            }
        }
        defer { firstGate.open() }

        try await waitUntil {
            checkout.pendingOperations.count == 1 && firstGate.isWaiting
        }

        let secondTask = Task { @MainActor in
            try await checkout.enqueueSessionUpdate {
                events.append("second ran")
            }
        }

        try await waitUntil {
            checkout.pendingOperations.count == 2
        }
        XCTAssertEqual(events, ["first started"])
        XCTAssertTrue(checkout.state.isLoading)

        firstGate.open()
        try await firstTask.value
        try await secondTask.value

        XCTAssertEqual(events, ["first started", "first finished", "second ran"])
        XCTAssertTrue(checkout.pendingOperations.isEmpty)
        XCTAssertFalse(checkout.state.isLoading)
    }

    func testAwaitPendingOperationsWaitsForQueuedWork() async throws {
        let checkout = makeCheckoutWithOpenSession()
        let gate = CheckoutPendingOperationsTestGate()
        var waiterCompleted = false

        let operationTask = Task { @MainActor in
            try await checkout.enqueueSessionUpdate {
                await gate.wait()
            }
        }
        defer { gate.open() }

        try await waitUntil {
            checkout.pendingOperations.count == 1 && gate.isWaiting
        }

        var waiterStarted = false
        let waiterTask = Task { @MainActor in
            waiterStarted = true
            try await checkout.awaitPendingOperations(timeout: 1)
            waiterCompleted = true
        }

        try await waitUntil {
            waiterStarted
        }
        XCTAssertFalse(waiterCompleted)

        gate.open()
        try await operationTask.value
        try await waiterTask.value

        XCTAssertTrue(waiterCompleted)
        XCTAssertTrue(checkout.pendingOperations.isEmpty)
        XCTAssertFalse(checkout.state.isLoading)
    }

    func testAwaitPendingOperationsTimesOutWithoutCancelingQueuedWork() async throws {
        let checkout = makeCheckoutWithOpenSession()
        let gate = CheckoutPendingOperationsTestGate()

        let operationTask = Task { @MainActor in
            try await checkout.enqueueSessionUpdate {
                await gate.wait()
            }
        }
        defer { gate.open() }

        try await waitUntil {
            checkout.pendingOperations.count == 1 && gate.isWaiting
        }

        do {
            try await checkout.awaitPendingOperations(timeout: 0.01)
            XCTFail("Expected CheckoutError.timedOut")
        } catch let error as CheckoutError {
            guard case .timedOut = error else {
                XCTFail("Expected .timedOut, got \(error)")
                return
            }
        }

        XCTAssertEqual(checkout.pendingOperations.count, 1)
        XCTAssertTrue(checkout.state.isLoading)

        gate.open()
        try await operationTask.value
        try await checkout.awaitPendingOperations(timeout: 1)

        XCTAssertTrue(checkout.pendingOperations.isEmpty)
        XCTAssertFalse(checkout.state.isLoading)
    }

    // MARK: - Helpers

    private func makeCheckoutWithOpenSession() -> Checkout {
        let session = CheckoutTestHelpers.makeOpenSession()
        return Checkout(clientSecret: "cs_test_123_secret_abc", session: session)
    }

    private func waitUntil(
        timeout: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() >= deadline {
                XCTFail("Condition not met within \(timeout) seconds", file: file, line: line)
                throw CheckoutPendingOperationsTestTimeoutError()
            }
            await Task.yield()
        }
    }
}

private struct CheckoutPendingOperationsTestTimeoutError: Error {}

@MainActor
private final class CheckoutPendingOperationsTestGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private(set) var isWaiting = false

    func wait() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.isWaiting = true
        }
        isWaiting = false
    }

    func open() {
        continuation?.resume()
        continuation = nil
    }
}
