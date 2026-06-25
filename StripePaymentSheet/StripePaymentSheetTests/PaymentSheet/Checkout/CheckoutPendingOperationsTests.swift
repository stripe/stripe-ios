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

    func testEnqueueSessionUpdateSerializesOperations() async throws {
        let checkout = await makeCheckoutWithOpenSession()
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

        firstGate.open()
        try await firstTask.value
        try await secondTask.value

        XCTAssertEqual(events, ["first started", "first finished", "second ran"])
        XCTAssertTrue(checkout.pendingOperations.isEmpty)
    }

    func testAwaitPendingOperationsWaitsForQueuedWork() async throws {
        let checkout = await makeCheckoutWithOpenSession()
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
    }

    func testAwaitPendingOperationsTimesOutWithoutCancelingQueuedWork() async throws {
        let checkout = await makeCheckoutWithOpenSession()
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

        gate.open()
        try await operationTask.value
        try await checkout.awaitPendingOperations(timeout: 1)

        XCTAssertTrue(checkout.pendingOperations.isEmpty)
    }

    // MARK: - Delegate skipping

    func testCommitSessionSkipsDelegateWhenAnotherOpIsQueued() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = AwaitsPendingOpsIntegrationDelegate()
        checkout.integrationDelegate = delegate

        let gate = CheckoutPendingOperationsTestGate()

        let firstTask = Task { @MainActor in
            try await checkout.enqueueSessionUpdate {
                await gate.wait()
                try await checkout.commitSession(CheckoutTestHelpers.makeOpenSession())
            }
        }

        try await waitUntil { checkout.pendingOperations.count == 1 }

        let secondTask = Task { @MainActor in
            try await checkout.enqueueSessionUpdate { }
        }

        try await waitUntil { checkout.pendingOperations.count == 2 }

        gate.open()

        let result = await withTimeout(3) { @MainActor in
            _ = try await firstTask.value
            _ = try await secondTask.value
        }

        if case .failure(let error) = result {
            if error is TimeoutError {
                XCTFail("Deadlocked — commitSession should skip delegate when another op is queued")
            } else {
                throw error
            }
        }

        XCTAssertTrue(checkout.pendingOperations.isEmpty)
    }

    // MARK: - Loading & Emission Tests

    func testLoadingStatePersistsAcrossConsecutiveQueuedOperations() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = CheckoutPendingOperationsTestDelegate()
        checkout.delegate = delegate

        var sessionEmissions: [Checkout.Session] = []
        let sessionSub = checkout.$session.dropFirst().sink { sessionEmissions.append($0) }
        var loadingEmissions: [Bool] = []
        let loadingSub = checkout.$isLoading.dropFirst().sink { loadingEmissions.append($0) }

        let firstGate = CheckoutPendingOperationsTestGate()
        let secondGate = CheckoutPendingOperationsTestGate()

        var firstJSON = CheckoutTestHelpers.makeOpenSessionJSON()
        firstJSON["currency"] = "eur"
        let firstSession = STPCheckoutSession.decodedObject(fromAPIResponse: firstJSON)!

        var secondJSON = CheckoutTestHelpers.makeOpenSessionJSON()
        secondJSON["currency"] = "gbp"
        let secondSession = STPCheckoutSession.decodedObject(fromAPIResponse: secondJSON)!

        // Enqueue first operation
        let firstTask = Task { @MainActor in
            try await checkout.enqueueSessionUpdate {
                await firstGate.wait()
                try await checkout.commitSession(firstSession)
            }
        }

        try await waitUntil { checkout.pendingOperations.count == 1 && firstGate.isWaiting }

        // Enqueue second operation before first finishes
        let secondTask = Task { @MainActor in
            try await checkout.enqueueSessionUpdate {
                await secondGate.wait()
                try await checkout.commitSession(secondSession)
            }
        }

        try await waitUntil { checkout.pendingOperations.count == 2 }

        // While first is in progress: isLoading=true emitted once, no session or finishLoading yet
        XCTAssertTrue(checkout.isLoading)
        XCTAssertEqual(loadingEmissions, [true])
        XCTAssertEqual(sessionEmissions.count, 0)
        XCTAssertEqual(delegate.beginLoadingCallCount, 1)
        XCTAssertEqual(delegate.finishLoadingCallCount, 0)
        XCTAssertEqual(delegate.updateSessionCallCount, 0)

        // Complete first operation, wait for second to start
        firstGate.open()
        try await waitUntil { secondGate.isWaiting }

        // While second is in progress: isLoading still true, session emitted once from first op
        XCTAssertTrue(checkout.isLoading)
        XCTAssertEqual(loadingEmissions, [true])
        XCTAssertEqual(sessionEmissions.count, 1)
        XCTAssertEqual(sessionEmissions[0].currency, "eur")
        XCTAssertEqual(delegate.beginLoadingCallCount, 1)
        XCTAssertEqual(delegate.finishLoadingCallCount, 0)
        XCTAssertEqual(delegate.updateSessionCallCount, 1)

        // Complete second operation
        secondGate.open()
        try await firstTask.value
        try await secondTask.value

        // After both complete: isLoading=false, both sessions emitted
        XCTAssertFalse(checkout.isLoading)
        XCTAssertEqual(loadingEmissions, [true, false])
        XCTAssertEqual(sessionEmissions.count, 2)
        XCTAssertEqual(sessionEmissions[1].currency, "gbp")
        XCTAssertEqual(delegate.beginLoadingCallCount, 1)
        XCTAssertEqual(delegate.finishLoadingCallCount, 1)
        XCTAssertEqual(delegate.updateSessionCallCount, 2)

        sessionSub.cancel()
        loadingSub.cancel()
    }

    func testThrowingOperationEmitsLoadingButNoSessionUpdate() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = CheckoutPendingOperationsTestDelegate()
        checkout.delegate = delegate

        var sessionEmissions: [Checkout.Session] = []
        let sessionSub = checkout.$session.dropFirst().sink { sessionEmissions.append($0) }
        var loadingEmissions: [Bool] = []
        let loadingSub = checkout.$isLoading.dropFirst().sink { loadingEmissions.append($0) }

        do {
            try await checkout.enqueueSessionUpdate {
                throw NSError(domain: "test", code: 42)
            }
            XCTFail("Expected error to propagate")
        } catch {
            XCTAssertEqual((error as NSError).code, 42)
        }

        XCTAssertFalse(checkout.isLoading)
        XCTAssertEqual(loadingEmissions, [true, false])
        XCTAssertEqual(sessionEmissions.count, 0)
        XCTAssertEqual(delegate.beginLoadingCallCount, 1)
        XCTAssertEqual(delegate.finishLoadingCallCount, 1)
        XCTAssertEqual(delegate.updateSessionCallCount, 0)

        sessionSub.cancel()
        loadingSub.cancel()
    }

    func testNoOpOperationStillEmitsSessionUpdate() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = CheckoutPendingOperationsTestDelegate()
        checkout.delegate = delegate

        var sessionEmissions: [Checkout.Session] = []
        let sessionSub = checkout.$session.dropFirst().sink { sessionEmissions.append($0) }

        // Enqueue an operation that commits the same session (no actual mutation)
        let existingSession = checkout.stpSession!
        try await checkout.enqueueSessionUpdate {
            try await checkout.commitSession(existingSession)
        }

        XCTAssertEqual(delegate.updateSessionCallCount, 1)
        XCTAssertEqual(sessionEmissions.count, 1)

        sessionSub.cancel()
    }

    // MARK: - Helpers

    private func makeCheckoutWithOpenSession() async -> Checkout {
        let session = CheckoutTestHelpers.makeOpenSession()
        return await Checkout(clientSecret: "cs_test_123_secret_abc", session: session)
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

@MainActor
private final class AwaitsPendingOpsIntegrationDelegate: CheckoutIntegrationDelegate {
    var isSheetPresented: Bool = false

    func checkoutDidUpdate(_ checkout: Checkout) async throws {
        try await checkout.awaitPendingOperations()
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

@MainActor
private class CheckoutPendingOperationsTestDelegate: CheckoutDelegate {
    var beginLoadingCallCount = 0
    var finishLoadingCallCount = 0
    var updateSessionCallCount = 0

    func checkoutDidBeginLoading(_ checkout: Checkout) {
        beginLoadingCallCount += 1
    }

    func checkoutDidFinishLoading(_ checkout: Checkout) {
        finishLoadingCallCount += 1
    }

    func checkoutDidUpdateSession(_ checkout: Checkout, session: Checkout.Session) {
        updateSessionCallCount += 1
    }
}
