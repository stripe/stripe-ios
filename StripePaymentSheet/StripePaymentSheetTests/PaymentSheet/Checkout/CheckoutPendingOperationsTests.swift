//
//  CheckoutPendingOperationsTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 5/7/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
import XCTest

@MainActor
final class CheckoutPendingOperationsTests: XCTestCase {

    func testEnqueueSessionUpdateSerializesOperations() async throws {
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
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
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
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
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
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

    // MARK: - Wallet Confirmation

    func testApplePayConfirmationCannotStartWhileAnUpdateIsPending() async throws {
        // Given an update that already owns the queue
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        let gate = CheckoutPendingOperationsTestGate()
        let update = Task { @MainActor in
            try await checkout.enqueueSessionUpdate {
                await gate.wait()
            }
        }
        defer { gate.open() }
        try await waitUntil { gate.isWaiting && checkout.pendingOperations.count == 1 }

        // When Apple Pay enters the confirmation coordinator
        let result = await checkout.confirm(source: .expressCheckoutElement) {
            .applePay(.makeMock(apiClient: checkout.apiClient))
        }

        // Then it is rejected before a wallet can be presented or deliver contact callbacks
        guard case .failed(let error) = result else {
            return XCTFail("Expected confirmation to be rejected, got \(result)")
        }
        XCTAssertTrue(error.nonGenericDescription.contains("Checkout Session is updating"))
        XCTAssertFalse(checkout.confirmationInProgress)
        XCTAssertEqual(checkout.pendingOperations.count, 1)
        gate.open()
        try await update.value
    }

    func testUpdateEmailUsesLatestQueuedValue() async throws {
        // Given a Checkout Session with a blocked update
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeConfiguration(
                paymentElementConfiguration: nil,
                expressCheckoutElementConfiguration: nil
            )
        )
        let gate = CheckoutPendingOperationsTestGate()
        let blockingTask = Task { @MainActor in
            try await checkout.enqueueSessionUpdate {
                await gate.wait()
            }
        }
        defer { gate.open() }
        try await waitUntil {
            checkout.pendingOperations.count == 1 && gate.isWaiting
        }

        // When an email is set and then cleared while the first update is blocked
        let setEmailTask = Task { @MainActor in
            try await checkout.updateEmail("local@example.com")
        }
        try await waitUntil {
            checkout.pendingOperations.count == 2
        }
        let clearEmailTask = Task { @MainActor in
            try await checkout.updateEmail(nil)
        }
        try await waitUntil {
            checkout.pendingOperations.count == 3
        }
        gate.open()
        try await blockingTask.value
        try await setEmailTask.value
        try await clearEmailTask.value

        // Then the latest queued email wins
        XCTAssertNil(checkout.session.email)
        XCTAssertTrue(checkout.pendingOperations.isEmpty)
    }

    // MARK: - Shipping Updates

    func testQueuedShippingSetThenClearPreservesLatestValue() async throws {
        try await assertShippingUpdates(initial: nil, first: "A", last: nil)
    }

    func testQueuedShippingChangeThenRestorePreservesLatestValue() async throws {
        try await assertShippingUpdates(initial: "A", first: "B", last: "A")
    }

    func testQueuedShippingClearThenRestorePreservesLatestValue() async throws {
        try await assertShippingUpdates(initial: "A", first: nil, last: "A")
    }

    func testQueuedShippingChangesUseLastDistinctAddress() async throws {
        try await assertShippingUpdates(initial: "A", first: "B", last: "C")
    }

    func testSequentialShippingSetThenClearPreservesLatestValue() async throws {
        try await assertShippingUpdates(initial: nil, first: "A", last: nil, overlapping: false)
    }

    private func assertShippingUpdates(
        initial: String?,
        first: String?,
        last: String?,
        overlapping: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        // Given shipping-sourced automatic tax, so each address update awaits a request.
        // No Shipping Address Element is configured or involved in this test.
        let response = CheckoutTestHelpers.makeSession([
            "automatic_tax": ["enabled": true, "status": "ready", "address_source": "shipping"],
            "shipping_address_collection": ["allowed_countries": ["US"]],
        ])
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration(
            apiResponse: response,
            paymentElementConfiguration: nil,
            expressCheckoutElementConfiguration: nil
        ))
        addTeardownBlock { HTTPStubs.removeAllStubs() }
        stub { $0.url?.path.hasSuffix("/update") == true } response: { _ in
            HTTPStubsResponse(jsonObject: response.allResponseFields, statusCode: 200, headers: nil)
                .responseTime(0.2)
        }
        func address(_ name: String?) -> CheckoutController.Address? {
            name.map { .init(country: "US", line1: "\($0) Street", city: "San Francisco", state: "CA", postalCode: "94103") }
        }
        try await checkout.updateShippingAddress(name: initial, address: address(initial))

        // When the merchant makes two public API calls, either overlapping or sequential.
        let firstUpdate = Task { @MainActor in
            try await checkout.updateShippingAddress(name: first, address: address(first))
        }
        if overlapping {
            try await waitUntil { checkout.isUpdating }
            XCTAssertEqual(checkout.session.shippingAddress?.name, initial, file: file, line: line)
        } else {
            try await firstUpdate.value
        }
        try await checkout.updateShippingAddress(name: last, address: address(last))
        try await firstUpdate.value

        // Then both calls succeeded, and the final session should reflect the later call.
        XCTAssertFalse(checkout.isUpdating, file: file, line: line)
        XCTAssertEqual(checkout.session.shippingAddress?.name, last, file: file, line: line)
        XCTAssertEqual(checkout.session.shippingAddress?.address, address(last), file: file, line: line)
    }

    // MARK: - Loading & Emission Tests

    func testLoadingStatePersistsAcrossConsecutiveQueuedOperations() async throws {
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        let recorder = CheckoutEmissionRecorder(checkout)

        // Gates let us pause each operation mid-flight so we can assert state at precise moments
        let firstGate = CheckoutPendingOperationsTestGate()
        let secondGate = CheckoutPendingOperationsTestGate()

        // Two distinct sessions (different currencies) so we can tell them apart
        var firstJSON = CheckoutTestHelpers.openSessionJSON
        firstJSON["presentment_currency"] = "eur"
        firstJSON["integration_currency"] = "eur"
        firstJSON["items"] = CheckoutTestHelpers.makeOneTimePriceCheckoutItems(currency: "eur")
        let firstSession = try CheckoutClientAPIResponse.decode(fromAPIResponse: firstJSON)

        var secondJSON = CheckoutTestHelpers.openSessionJSON
        secondJSON["presentment_currency"] = "gbp"
        secondJSON["integration_currency"] = "gbp"
        secondJSON["items"] = CheckoutTestHelpers.makeOneTimePriceCheckoutItems(currency: "gbp")
        let secondSession = try CheckoutClientAPIResponse.decode(fromAPIResponse: secondJSON)

        // First op blocks on firstGate until we explicitly open it
        let firstTask = Task { @MainActor in
            try await checkout.enqueueSessionUpdate {
                await firstGate.wait()
                checkout.commitSession(firstSession)
                checkout.updateForSessionChange()
            }
        }

        try await waitUntil { checkout.pendingOperations.count == 1 && firstGate.isWaiting }

        // Second op enqueued while first is still in progress
        let secondTask = Task { @MainActor in
            try await checkout.enqueueSessionUpdate {
                await secondGate.wait()
                checkout.commitSession(secondSession)
                checkout.updateForSessionChange()
            }
        }

        try await waitUntil { checkout.pendingOperations.count == 2 }

        XCTContext.runActivity(named: "While first op is blocked") { _ in
            XCTAssertTrue(checkout.isUpdating)
            XCTAssertEqual(recorder.loading, [true])
            XCTAssertEqual(recorder.sessions.count, 0)
        }

        firstGate.open()
        try await waitUntil { secondGate.isWaiting }

        // Key behavior: isUpdating doesn't toggle off between queued operations
        XCTContext.runActivity(named: "Between ops — loading persists, first session committed") { _ in
            XCTAssertTrue(checkout.isUpdating)
            XCTAssertEqual(recorder.loading, [true])
            XCTAssertEqual(recorder.sessions.count, 2)
            XCTAssertEqual(recorder.sessions.last?.currency, "eur")
        }

        secondGate.open()
        try await firstTask.value
        try await secondTask.value

        // loading transitioned true→false exactly once across both operations
        XCTContext.runActivity(named: "After both ops complete") { _ in
            XCTAssertFalse(checkout.isUpdating)
            XCTAssertEqual(recorder.loading, [true, false])
            XCTAssertEqual(recorder.sessions.count, 4)
            XCTAssertEqual(recorder.sessions.last?.currency, "gbp")
        }
    }

    func testThrowingOperationEmitsLoadingButNoSessionUpdate() async throws {
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        let recorder = CheckoutEmissionRecorder(checkout)

        do {
            try await checkout.enqueueSessionUpdate {
                throw NSError(domain: "test", code: 42)
            }
            XCTFail("Expected error to propagate")
        } catch {
            XCTAssertEqual((error as NSError).code, 42)
        }

        XCTAssertFalse(checkout.isUpdating)
        XCTAssertEqual(recorder.loading, [true, false])
        XCTAssertEqual(recorder.sessions.count, 0)
    }

    func testNoOpOperationStillEmitsSessionUpdate() async throws {
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        let recorder = CheckoutEmissionRecorder(checkout)

        // Enqueue an operation that commits the same session (no actual mutation)
        let existingSession = CheckoutTestHelpers.makeOpenSession()
        try await checkout.enqueueSessionUpdate {
            checkout.commitSession(existingSession)
            checkout.updateForSessionChange()
        }

        XCTAssertEqual(recorder.sessions.count, 2)
    }

    private func waitUntil(
        timeout: TimeInterval = 5,
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
            try await Task.sleep(nanoseconds: 1_000_000)
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
