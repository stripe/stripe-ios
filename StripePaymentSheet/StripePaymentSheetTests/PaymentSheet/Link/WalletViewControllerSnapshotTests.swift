//
//  WalletViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Till Hellmund on 9/9/25.
//

import Foundation
import StripeCoreTestUtils
import StripePaymentsTestUtils
@_spi(STP) import StripeUICore
import XCTest

@testable@_spi(STP) import StripePaymentSheet

// @iOS26
final class WalletViewControllerSnapshotTests: STPSnapshotTestCase {

    override static func setUp() {
        if #available(iOS 26, *) {
            var configuration = PaymentSheet.Configuration()
            configuration.appearance.applyLiquidGlass()
            LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        }
    }

    func testDefault() {
        let sut = makeSUT()
        verify(sut.view)
    }

    func testWithApplePay() {
        let sut = makeSUT(shouldOfferApplePay: true)
        verify(sut.view)
    }

    func testAlternativeCTA() {
        let sut = makeSUT(callToAction: .continue)
        verify(sut.view)
    }

    func testWithCvcRecollection() {
        let sut = makeSUT(initiallySelectedPaymentDetailsID: "2")
        verify(sut.view)
    }

    func testWithExpiryDateRecollection() {
        let sut = makeSUT(initiallySelectedPaymentDetailsID: "4")
        verify(sut.view)
    }

    func testWithError() {
        let sut = makeSUT()
        let error = NSError.stp_genericConnectionError()
        sut.updateErrorLabel(for: error)
        verify(sut.view)
    }

    func testWithMandate() {
        let sut = makeSUT(setupFutureUsage: true)
        verify(sut.view)
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

extension WalletViewControllerSnapshotTests {

    func makeSUT(
        shouldOfferApplePay: Bool = false,
        initiallySelectedPaymentDetailsID: String? = nil,
        callToAction: ConfirmButton.CallToActionType? = nil,
        linkFundingSources: [String] = ["CARD", "BANK_ACCOUNT"],
        linkPassthroughModeEnabled: Bool = false,
        disallowedBrands: [PaymentSheet.CardBrandAcceptance.BrandCategory] = [],
        paymentMethods: [ConsumerPaymentDetails] = LinkStubs.paymentMethods(),
        setupFutureUsage: Bool? = nil
    ) -> PayWithLinkViewController.WalletViewController {
        var configuration = PaymentSheet.Configuration()

        if !disallowedBrands.isEmpty {
            configuration.cardBrandAcceptance = .disallowed(brands: disallowedBrands)
        }

        let (intent, elementsSession) = try! PayWithLinkTestHelpers.makePaymentIntentAndElementsSession(
            linkFundingSources: linkFundingSources,
            linkPassthroughModeEnabled: linkPassthroughModeEnabled,
            linkPMOSFU: setupFutureUsage
        )
        let session = LinkStubs.consumerSession()

        let linkAccount = PaymentSheetLinkAccount(
            email: "test@stripe.com",
            session: session,
            publishableKey: "pk_123",
            displayablePaymentDetails: nil,
            useMobileEndpoints: true
        )

        return PayWithLinkViewController.WalletViewController(
            linkAccount: linkAccount,
            context: .init(
                intent: intent,
                elementsSession: elementsSession,
                configuration: configuration,
                shouldOfferApplePay: shouldOfferApplePay,
                shouldFinishOnClose: false,
                canSkipWalletAfterVerification: false,
                initiallySelectedPaymentDetailsID: initiallySelectedPaymentDetailsID,
                callToAction: callToAction,
                analyticsHelper: ._testValue()
            ),
            paymentMethods: paymentMethods
        )
    }
}
