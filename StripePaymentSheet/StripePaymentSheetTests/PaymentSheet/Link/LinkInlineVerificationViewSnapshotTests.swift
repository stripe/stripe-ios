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
