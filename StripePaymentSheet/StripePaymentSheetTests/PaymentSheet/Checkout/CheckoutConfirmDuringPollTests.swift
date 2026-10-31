//
//  CheckoutConfirmDuringPollTests.swift
//  StripePaymentSheetTests
//
//  Verifies the "no double charges" guarantee specifically during the poll phase of
//  confirmation (after /confirm returns status "open" and CheckoutController is polling
//  for a terminal result), which is not covered by the existing duplicate-confirmation
//  coverage in CheckoutConfirmationStubbedTests (that coverage only delays the initial
//  /confirm response, not the subsequent /poll request).

import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(InternalOnlyAPI) import StripeCore
import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
import UIKit
import XCTest

@MainActor
final class CheckoutConfirmDuringPollTests: APIStubbedTestCase {

    func testConfirmRejectsDuplicateConfirmationDuringPollPhase() async throws {
        // Given a confirmation whose /confirm request returns quickly with status "open",
        // which puts CheckoutController into its poll phase, and whose /poll request is
        // slow enough to observe.
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeConfiguration(apiResponse: CheckoutTestHelpers.makeOpenSession())
        )

        var confirmedJSON = STPTestUtils.jsonNamed("CheckoutSessionConfirmed")!
        confirmedJSON["id"] = checkout.session.id
        confirmedJSON["client_secret"] = checkout.clientSecret
        confirmedJSON["status"] = "open"
        confirmedJSON["payment_status"] = "unpaid"

        stub { request in
            request.url?.path.hasSuffix("/confirm") == true
        } response: { _ in
            HTTPStubsResponse(jsonObject: confirmedJSON, statusCode: 200, headers: nil)
        }

        let pollJSON: [AnyHashable: Any] = [
            "id": checkout.session.id,
            "confirmation_status": "succeeded",
            "status": "complete",
            "payment_status": "paid",
        ]
        stub { request in
            request.httpMethod == "GET" && request.url?.path.hasSuffix("/poll") == true
        } response: { _ in
            HTTPStubsResponse(jsonObject: pollJSON, statusCode: 200, headers: nil).responseTime(0.75)
        }

        let configuration = checkout.getPaymentElement().embeddedPaymentElement.configuration
        let firstFlow = CheckoutController.CheckoutConfirmationFlow.paymentMethod(
            .init(
                option: .saved(STPPaymentMethod._testCard(), nil),
                configuration: configuration,
                nativeSheetPresentation: checkout.getPaymentElement().embeddedPaymentElement.nativeSheetPresentation,
                confirmationChallenge: nil,
                authenticationContext: self,
                paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
                attribution: .init(confirmingElement: .paymentElement, configuredElements: checkout.configuration.configuredElements)
            ),
            preconfirmIntegrationShape: .embedded
        )

        let firstConfirmation = Task { @MainActor in
            await checkout.confirm(source: .merchant) { firstFlow }
        }

        // When a second confirmation is attempted while the first is in its poll phase
        // (i.e. after /confirm has already returned "open" and settled, but before /poll
        // has resolved to a terminal state).
        try await waitUntil {
            checkout.confirmationInProgress && checkout.pendingOperations.count == 1
        }
        // Bias toward being inside the (slow) /poll call rather than the (fast) /confirm call,
        // since confirmationInProgress is set before either request and there's no signal
        // exposed for "now polling" specifically.
        try await Task.sleep(nanoseconds: 150_000_000)

        let secondFlow = CheckoutController.CheckoutConfirmationFlow.paymentMethod(
            .init(
                option: .saved(STPPaymentMethod._testCard(), nil),
                configuration: configuration,
                nativeSheetPresentation: checkout.getPaymentElement().embeddedPaymentElement.nativeSheetPresentation,
                confirmationChallenge: nil,
                authenticationContext: self,
                paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
                attribution: .init(confirmingElement: .paymentElement, configuredElements: checkout.configuration.configuredElements)
            ),
            preconfirmIntegrationShape: .embedded
        )
        let duplicateResult = await checkout.confirm(source: .merchant) { secondFlow }

        // Then the duplicate is rejected without disturbing the first (in-flight, polling) confirmation.
        guard case .failed(let error) = duplicateResult else {
            XCTFail("Expected duplicate confirmation during poll phase to fail, got \(duplicateResult)")
            return
        }
        XCTAssertTrue(error.nonGenericDescription.contains("second confirmation"), error.nonGenericDescription)

        let firstResult = await firstConfirmation.value
        guard case .completed(let paymentStatus) = firstResult else {
            XCTFail("Expected first confirmation to complete, got \(firstResult)")
            return
        }
        XCTAssertEqual(paymentStatus, .paid)
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
                throw CheckoutConfirmDuringPollTestTimeoutError()
            }
            try await Task.sleep(nanoseconds: 1_000_000)
        }
    }
}

extension CheckoutConfirmDuringPollTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        UIViewController()
    }
}

private struct CheckoutConfirmDuringPollTestTimeoutError: Error {}
