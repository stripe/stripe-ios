//
//  PayWithLinkViewController-UpdatePaymentViewControllerTests.swift
//  StripeiOS Tests
//
//  Created by Jeremy Kelleher on 9/23/25.
//

import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripeUICore

class PayWithLinkViewController_UpdatePaymentViewControllerTests: STPSnapshotTestCase {

    override func setUpWithError() throws {

        if #available(iOS 26, *) {
            var configuration = PaymentSheet.Configuration()
            configuration.appearance.applyLiquidGlass()
            LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        }

        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)

    }

    func testBillingDetailsUpdateFlow() throws {
        let sut = try makeSUT(isBillingDetailsUpdateFlow: true)
        verify(sut)
    }

    func testNotBillingDetailsUpdateFlow() throws {
        let sut = try makeSUT(isBillingDetailsUpdateFlow: false)
        verify(sut)
    }

    func verify(
        _ element: PayWithLinkViewController.UpdatePaymentViewController,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        element.view.autosizeHeight(width: 340)
        STPSnapshotVerifyView(element.view, identifier: identifier, file: file, line: line)
    }

}

extension PayWithLinkViewController_UpdatePaymentViewControllerTests{

    func makeSUT(isBillingDetailsUpdateFlow: Bool) throws -> PayWithLinkViewController.UpdatePaymentViewController {

        let (intent, elementsSession) = try PayWithLinkTestHelpers.makePaymentIntentAndElementsSession()

        var paymentSheetConfiguration = PaymentSheet.Configuration()
        paymentSheetConfiguration.cardBrandAcceptance = .all

        return PayWithLinkViewController.UpdatePaymentViewController(
            linkAccount: LinkStubs.account(),
            context: .init(
                intent: intent,
                elementsSession: elementsSession,
                configuration: paymentSheetConfiguration,
                shouldOfferApplePay: false,
                shouldFinishOnClose: false,
                shouldShowSecondaryCta: true,
                canSkipWalletAfterVerification: false,
                initiallySelectedPaymentDetailsID: nil,
                callToAction: nil,
                analyticsHelper: ._testValue()
            ),
            paymentMethod: try XCTUnwrap(LinkStubs.paymentMethods().first, "Expecting one payment method"),
            isBillingDetailsUpdateFlow: isBillingDetailsUpdateFlow
        )

    }
}
