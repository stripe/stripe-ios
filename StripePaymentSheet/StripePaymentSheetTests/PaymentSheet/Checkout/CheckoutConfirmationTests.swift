//
//  CheckoutConfirmationTests.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
import UIKit
import XCTest

@MainActor
final class CheckoutConfirmationTests: APIStubbedTestCase {

    func testConfirmCommitsReturnedSessionAndMapsSuccess() async throws {
        // Given an open Checkout Session whose confirmation succeeds
        let checkout = try await makeCheckout()
        stubConfirmation()

        // When the coordinator confirms the selected payment method
        let result = await checkout.confirm(makePaymentMethodFlow(for: checkout))

        // Then it maps the result and commits the returned Checkout Session
        guard case .succeeded(let paymentStatus) = result else {
            XCTFail("Expected confirmation to succeed, got \(result)")
            return
        }
        XCTAssertEqual(paymentStatus, .paid)
        XCTAssertEqual(checkout.session.status, .complete(.paid))
    }

    func testConfirmRejectsDuplicateConfirmation() async throws {
        // Given a confirmation that remains in progress long enough to start another
        let checkout = try await makeCheckout()
        stubConfirmation(responseTime: 0.5)
        let firstConfirmation = Task { @MainActor in
            await checkout.confirm(makePaymentMethodFlow(for: checkout))
        }

        try await waitUntil {
            checkout.confirmationInProgress && checkout.pendingOperations.count == 1
        }

        // When another confirmation starts
        let duplicateResult = await checkout.confirm(makePaymentMethodFlow(for: checkout))

        // Then the duplicate fails without disturbing the first confirmation
        guard case .failed(let error) = duplicateResult else {
            XCTFail("Expected duplicate confirmation to fail, got \(duplicateResult)")
            return
        }
        XCTAssertTrue(error.nonGenericDescription.contains("second confirmation"))
        assertSucceeded(await firstConfirmation.value)
    }

    func testSessionUpdateQueuedDuringConfirmationWaitsForConfirmation() async throws {
        // Given an in-progress confirmation
        let checkout = try await makeCheckout()
        stubConfirmation(responseTime: 0.5)
        let confirmation = Task { @MainActor in
            await checkout.confirm(makePaymentMethodFlow(for: checkout))
        }

        try await waitUntil {
            checkout.confirmationInProgress && checkout.pendingOperations.count == 1
        }

        // When a session update is queued behind it
        var updateExecuted = false
        let update = Task { @MainActor in
            await checkout.enqueueSessionUpdate {
                updateExecuted = true
            }
        }
        try await waitUntil { checkout.pendingOperations.count == 2 }

        // Then the update waits until confirmation has finished
        XCTAssertFalse(updateExecuted)
        assertSucceeded(await confirmation.value)
        await update.value
        XCTAssertTrue(updateExecuted)
        XCTAssertTrue(checkout.pendingOperations.isEmpty)
    }

    func testConfirmRejectsClosedSessionWithoutCallingConfirmAPI() async throws {
        // Given a Checkout Session that is already complete
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeConfiguration(apiResponse: CheckoutTestHelpers.makeClosedSession())
        )
        let confirmRequest = expectation(description: "Confirmation API is not called")
        confirmRequest.isInverted = true
        stub { request in
            request.url?.path.hasSuffix("/confirm") == true
        } response: { _ in
            confirmRequest.fulfill()
            return HTTPStubsResponse(jsonObject: Self.confirmedSessionJSON, statusCode: 200, headers: nil)
        }

        // When confirmation is attempted
        let result = await checkout.confirm(makePaymentMethodFlow(for: checkout))

        // Then it fails validation before making an API request
        guard case .failed(let error) = result else {
            XCTFail("Expected confirmation of a closed session to fail, got \(result)")
            return
        }
        XCTAssertTrue(error.nonGenericDescription.contains("no longer open"))
        await fulfillment(of: [confirmRequest], timeout: 0.1)
    }

    // MARK: - Helpers

    private static var confirmedSessionJSON: [AnyHashable: Any] {
        var json = STPTestUtils.jsonNamed("CheckoutSessionConfirmed")!
        json["session_id"] = "cs_test_123"
        json["client_secret"] = "cs_test_123_secret_abc"
        return json
    }

    private func makeCheckout() async throws -> CheckoutController {
        try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
    }

    private func makePaymentMethodFlow(
        for checkout: CheckoutController
    ) -> CheckoutController.CheckoutConfirmationFlow {
        let configuration = checkout.getPaymentElement().embeddedPaymentElement.configuration
        let parameters = CheckoutController.PaymentMethodConfirmationParameters(
            option: .saved(STPPaymentMethod._testCard(), nil),
            configuration: configuration,
            confirmationChallenge: nil,
            authenticationContext: self,
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient)
        )
        return .paymentMethod(parameters, preconfirmIntegrationShape: .embedded)
    }

    private func stubConfirmation(responseTime: TimeInterval = 0) {
        stub { request in
            request.url?.path.hasSuffix("/confirm") == true
        } response: { _ in
            HTTPStubsResponse(
                jsonObject: Self.confirmedSessionJSON,
                statusCode: 200,
                headers: nil
            ).responseTime(responseTime)
        }
    }

    private func assertSucceeded(
        _ result: CheckoutController.ConfirmResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .succeeded(let paymentStatus) = result else {
            XCTFail("Expected confirmation to succeed, got \(result)", file: file, line: line)
            return
        }
        XCTAssertEqual(paymentStatus, .paid, file: file, line: line)
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
                throw CheckoutConfirmationTestTimeoutError()
            }
            try await Task.sleep(nanoseconds: 1_000_000)
        }
    }
}

extension CheckoutConfirmationTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        UIViewController()
    }
}

private struct CheckoutConfirmationTestTimeoutError: Error {}
