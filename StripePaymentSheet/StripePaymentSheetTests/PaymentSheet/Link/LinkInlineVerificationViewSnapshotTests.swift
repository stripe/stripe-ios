//
//  LinkInlineVerificationViewSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Mat Schmid on 7/23/25.
//

import StripeCoreTestUtils
@_spi(STP)@testable import StripePaymentSheet
@_spi(STP)@testable import StripePaymentsTestUtils
import SwiftUI
import UIKit

@MainActor
class LinkInlineVerificationViewSnapshotTests: STPSnapshotTestCase {
    private let frame = CGRect(x: 0, y: 0, width: 328, height: 328)
    private var testWindow: UIWindow?

    override func tearDown() {
        // CRITICAL: Properly dismiss and nil out the test window to ensure
        // any SwiftUI views and their async Tasks are cleaned up before the next test runs.
        // Without this, the LinkInlineVerificationView's .onAppear Task can still be running
        // and attempt to call start_verification, causing flaky test failures.
        testWindow?.rootViewController = nil
        testWindow?.isHidden = true
        testWindow = nil
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
        testWindow = UIWindow(frame: frame)
        testWindow?.rootViewController = vc
        testWindow?.makeKeyAndVisible()

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
        testWindow = UIWindow(frame: frame)
        testWindow?.rootViewController = vc
        testWindow?.makeKeyAndVisible()

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
        testWindow = UIWindow(frame: frame)
        testWindow?.rootViewController = vc
        testWindow?.makeKeyAndVisible()

        STPSnapshotVerifyView(vc.view, identifier: nil, file: #filePath, line: #line)
    }
}
