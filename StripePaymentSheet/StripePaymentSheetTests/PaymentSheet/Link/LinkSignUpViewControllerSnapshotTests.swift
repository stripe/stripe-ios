//
//  LinkSignUpViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Mat Schmid on 5/6/25.
//

import Foundation
import StripeCoreTestUtils
import StripePaymentsTestUtils
import XCTest

@testable@_spi(STP) import StripePaymentSheet

final class LinkSignUpViewControllerSnapshotTests: STPSnapshotTestCase {
    func testEmptyView() throws {
        let sut = try makeSUT(email: nil)
        sut.updateUI()

        verify(sut.stackView)
    }

    func testWithEmail() throws {
        let sut = try makeSUT(email: "user@example.com")
        sut.updateUI()

        verify(sut.stackView)
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 335)
        view.backgroundColor = .white
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}

extension LinkSignUpViewControllerSnapshotTests {

    func makeSUT(email: String?) throws -> PayWithLinkViewController.SignUpViewController {
        let (paymentIntent, elementsSession) = try PayWithLinkTestHelpers.makePaymentIntentAndElementsSession()
        let session = email == nil ? LinkStubs.consumerSession(supportedPaymentDetailsTypes: [.card]) : nil

        return PayWithLinkViewController.SignUpViewController(
            linkAccount: .init(
                email: email ?? "",
                session: session,
                publishableKey: nil,
                useMobileEndpoints: false
            ),
            context: .init(
                intent: paymentIntent,
                elementsSession: elementsSession,
                configuration: PaymentSheet.Configuration(),
                shouldOfferApplePay: false,
                shouldFinishOnClose: false,
                initiallySelectedPaymentDetailsID: nil,
                callToAction: nil,
                analyticsHelper: ._testValue()
            )
        )
    }
}
