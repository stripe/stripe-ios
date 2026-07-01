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
@testable @_spi(STP) import StripePaymentsTestUtils
@_spi(STP) import StripeUICore
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

    // MARK: - Confirm with pending operations

    func testEPEConfirmFailsWhenCheckoutPendingOperationsExist() async throws {
        await AddressSpecProvider.shared.loadAddressSpecs()

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

        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let elementsSession = STPElementsSession._testCardValue()
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
        let configuration = EmbeddedPaymentElement.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        let sut = EmbeddedPaymentElement(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue()
        )
        sut.checkout = checkout
        sut.presentingViewController = UIViewController()
        sut._test_paymentOption = .new(confirmParams: IntentConfirmParams(type: .stripe(.card)))

        let result = await sut.confirm()
        switch result {
        case .failed(let error):
            XCTAssertTrue(
                error.nonGenericDescription.contains("Checkout session is still loading"),
                "Expected error about pending loading state, got: \(error.nonGenericDescription)"
            )
        default:
            XCTFail("Expected confirm to fail due to pending operations, got: \(result)")
        }

        gate.open()
        _ = try? await operationTask.value
    }

    func testFCConfirmFailsWhenCheckoutPendingOperationsExist() async throws {
        await AddressSpecProvider.shared.loadAddressSpecs()

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

        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let elementsSession = STPElementsSession._testCardValue()
        let savedPaymentMethod = STPPaymentMethod._testCard()
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: [savedPaymentMethod],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "cus_test", ephemeralKeySecret: "ek_test")
        let fc = PaymentSheet.FlowController(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue()
        )
        fc.checkout = checkout

        STPAssertTestUtil.shouldSuppressNextSTPAlert = true

        let expectation = expectation(description: "Confirm completes")
        fc.confirm(from: UIViewController()) { result in
            switch result {
            case .failed(let error):
                XCTAssertTrue(
                    error.nonGenericDescription.contains("Checkout session is still loading"),
                    "Expected error about pending loading state, got: \(error.nonGenericDescription)"
                )
            default:
                XCTFail("Expected confirm to fail due to pending operations, got: \(result)")
            }
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertTrue(
            STPAssertTestUtil.lastAssertMessage.contains("Checkout session is loading"),
            "Expected assertion about Checkout session loading, got: \(STPAssertTestUtil.lastAssertMessage)"
        )

        gate.open()
        _ = try? await operationTask.value
    }

    // MARK: - Loading & Emission Tests

    func testLoadingStatePersistsAcrossConsecutiveQueuedOperations() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate
        let recorder = CheckoutEmissionRecorder(checkout)

        let firstGate = CheckoutPendingOperationsTestGate()
        let secondGate = CheckoutPendingOperationsTestGate()

        var firstJSON = CheckoutTestHelpers.makeOpenSessionJSON()
        firstJSON["currency"] = "eur"
        let firstSession = STPCheckoutSession.decodedObject(fromAPIResponse: firstJSON)!

        var secondJSON = CheckoutTestHelpers.makeOpenSessionJSON()
        secondJSON["currency"] = "gbp"
        let secondSession = STPCheckoutSession.decodedObject(fromAPIResponse: secondJSON)!

        let firstTask = Task { @MainActor in
            try await checkout.enqueueSessionUpdate {
                await firstGate.wait()
                try await checkout.commitSession(firstSession)
            }
        }

        try await waitUntil { checkout.pendingOperations.count == 1 && firstGate.isWaiting }

        let secondTask = Task { @MainActor in
            try await checkout.enqueueSessionUpdate {
                await secondGate.wait()
                try await checkout.commitSession(secondSession)
            }
        }

        try await waitUntil { checkout.pendingOperations.count == 2 }

        XCTContext.runActivity(named: "While first op is blocked") { _ in
            XCTAssertTrue(checkout.isLoading)
            XCTAssertEqual(recorder.loading, [true])
            XCTAssertEqual(recorder.sessions.count, 0)
            XCTAssertEqual(delegate.beginLoadingCallCount, 1)
            XCTAssertEqual(delegate.finishLoadingCallCount, 0)
            XCTAssertEqual(delegate.updateSessionCallCount, 0)
        }

        firstGate.open()
        try await waitUntil { secondGate.isWaiting }

        XCTContext.runActivity(named: "Between ops — loading persists, first session committed") { _ in
            XCTAssertTrue(checkout.isLoading)
            XCTAssertEqual(recorder.loading, [true])
            XCTAssertEqual(recorder.sessions.count, 1)
            XCTAssertEqual(recorder.sessions[0].currency, "eur")
            XCTAssertEqual(delegate.beginLoadingCallCount, 1)
            XCTAssertEqual(delegate.finishLoadingCallCount, 0)
            XCTAssertEqual(delegate.updateSessionCallCount, 1)
        }

        secondGate.open()
        try await firstTask.value
        try await secondTask.value

        XCTContext.runActivity(named: "After both ops complete") { _ in
            XCTAssertFalse(checkout.isLoading)
            XCTAssertEqual(recorder.loading, [true, false])
            XCTAssertEqual(recorder.sessions.count, 2)
            XCTAssertEqual(recorder.sessions[1].currency, "gbp")
            XCTAssertEqual(delegate.beginLoadingCallCount, 1)
            XCTAssertEqual(delegate.finishLoadingCallCount, 1)
            XCTAssertEqual(delegate.updateSessionCallCount, 2)
        }
    }

    func testThrowingOperationEmitsLoadingButNoSessionUpdate() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate
        let recorder = CheckoutEmissionRecorder(checkout)

        do {
            try await checkout.enqueueSessionUpdate {
                throw NSError(domain: "test", code: 42)
            }
            XCTFail("Expected error to propagate")
        } catch {
            XCTAssertEqual((error as NSError).code, 42)
        }

        XCTAssertFalse(checkout.isLoading)
        XCTAssertEqual(recorder.loading, [true, false])
        XCTAssertEqual(recorder.sessions.count, 0)
        XCTAssertEqual(delegate.beginLoadingCallCount, 1)
        XCTAssertEqual(delegate.finishLoadingCallCount, 1)
        XCTAssertEqual(delegate.updateSessionCallCount, 0)
    }

    func testNoOpOperationStillEmitsSessionUpdate() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate
        let recorder = CheckoutEmissionRecorder(checkout)

        let existingSession = checkout.stpSession!
        try await checkout.enqueueSessionUpdate {
            try await checkout.commitSession(existingSession)
        }

        XCTAssertEqual(delegate.updateSessionCallCount, 1)
        XCTAssertEqual(recorder.sessions.count, 1)
    }

    // MARK: - Helpers

    private func makeCheckoutWithOpenSession() async -> Checkout {
        await CheckoutTestHelpers.makeCheckoutWithOpenSession()
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
