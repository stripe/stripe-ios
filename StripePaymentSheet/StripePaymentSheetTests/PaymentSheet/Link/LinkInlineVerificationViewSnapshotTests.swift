//
//  LinkInlineVerificationViewSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Mat Schmid on 7/23/25.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
@_spi(STP)@testable import StripePaymentSheet
@_spi(STP)@testable import StripePaymentsTestUtils
import SwiftUI
import UIKit

@MainActor
class LinkInlineVerificationViewSnapshotTests: STPSnapshotTestCase {
    private let frame = CGRect(x: 0, y: 0, width: 328, height: 328)
    private nonisolated(unsafe) var verificationStub: HTTPStubsDescriptor?
    private nonisolated(unsafe) var verificationExpectation: XCTestExpectation?

    override func setUp() {
        super.setUp()
        // Stub the start_verification endpoint and track when it's called.
        // LinkInlineVerificationView triggers startVerification() on onAppear, so we need to
        // wait for this request to complete before tearDown to prevent it from interfering
        // with other tests using STPNetworkStubbingTestCase.
        // We create an XCTestExpectation directly (not via self.expectation) so it doesn't
        // fail the test if unfulfilled - we just use it for synchronization.
        verificationExpectation = XCTestExpectation(description: "start_verification called")
        verificationStub = stub(condition: isPath("/v1/consumers/sessions/start_verification")) { [weak self] _ in
            self?.verificationExpectation?.fulfill()
            let response: [String: Any] = [
                "consumer_session": [
                    "client_secret": "test_secret",
                    "email_address": "test@example.com",
                    "redacted_formatted_phone_number": "(***) *** **55",
                    "verification_sessions": [["type": "SMS", "state": "started"]],
                ],
            ]
            return HTTPStubsResponse(
                jsonObject: response,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }
    }

    override func tearDown() {
        // Wait for the async startVerification() request to complete before removing the stub.
        // This prevents the request from being caught by other tests' catch-all stubs.
        // Use XCTWaiter to avoid failing the test if the request hasn't happened yet.
        let waiter = XCTWaiter()
        _ = waiter.wait(for: [verificationExpectation!], timeout: 2.0)
        if let verificationStub {
            HTTPStubs.removeStub(verificationStub)
        }
        super.tearDown()
    }

    @available(iOS 16.0, *)
    func testLinkInlineVerificationView_NoPaymentMethodPreview() {
        let account = PaymentSheetLinkAccount._testValue(
            email: "jane.diaz@email.com",
            isRegistered: true,
            displayablePaymentDetails: nil
        )

        let verificationView = LinkInlineVerificationView(
            account: account,
            appearance: .default,
            onComplete: { }
        )

        let vc = UIHostingController(rootView: verificationView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: frame)
        window.rootViewController = vc
        window.makeKeyAndVisible()

        STPSnapshotVerifyView(vc.view, identifier: nil, file: #filePath, line: #line)
    }

    @available(iOS 16.0, *)
    func testLinkInlineVerificationView_WithVisaPaymentMethodPreview() {
        let displayablePaymentDetails = ConsumerSession.DisplayablePaymentDetails(
            defaultCardBrand: "VISA",
            defaultPaymentType: .card,
            last4: "4242"
        )

        let account = PaymentSheetLinkAccount._testValue(
            email: "jane.diaz@email.com",
            isRegistered: true,
            displayablePaymentDetails: displayablePaymentDetails
        )

        let verificationView = LinkInlineVerificationView(
            account: account,
            appearance: .default,
            onComplete: { }
        )

        let vc = UIHostingController(rootView: verificationView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: frame)
        window.rootViewController = vc
        window.makeKeyAndVisible()

        STPSnapshotVerifyView(vc.view, identifier: nil, file: #filePath, line: #line)
    }

    @available(iOS 16.0, *)
    func testLinkInlineVerificationView_WithBankPaymentMethodPreview() {
        let displayablePaymentDetails = ConsumerSession.DisplayablePaymentDetails(
            defaultCardBrand: nil,
            defaultPaymentType: .bankAccount,
            last4: "6789"
        )

        let account = PaymentSheetLinkAccount._testValue(
            email: "jane.diaz@email.com",
            isRegistered: true,
            displayablePaymentDetails: displayablePaymentDetails
        )

        let verificationView = LinkInlineVerificationView(
            account: account,
            appearance: .default,
            onComplete: { }
        )

        let vc = UIHostingController(rootView: verificationView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: frame)
        window.rootViewController = vc
        window.makeKeyAndVisible()

        STPSnapshotVerifyView(vc.view, identifier: nil, file: #filePath, line: #line)
    }
}
