//
//  PayWithLinkViewController-NewPaymentViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Jeremy Kelleher on 10/1/25.
//

import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripeUICore

class PayWithLinkViewController_NewPaymentViewControllerSnapshotTests: STPSnapshotTestCase {

    override func setUpWithError() throws {

        try super.setUpWithError()

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

    func testIsAddingFirstPaymentMethod() throws {
        let sut = try makeSUT(isAddingFirstPaymentMethod: true)
        verify(sut)
    }

    func testIsNotAddingFirstPaymentMethod() throws {
        let sut = try makeSUT(isAddingFirstPaymentMethod: false)
        verify(sut)
    }

    func verify(
        _ element: PayWithLinkViewController.NewPaymentViewController,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        element.view.autosizeHeight(width: 340)
        STPSnapshotVerifyView(element.view, identifier: identifier, file: file, line: line)
    }

}

extension PayWithLinkViewController_NewPaymentViewControllerSnapshotTests {

    func makeSUT(isAddingFirstPaymentMethod: Bool) throws -> PayWithLinkViewController.NewPaymentViewController {

        let (intent, elementsSession) = try PayWithLinkTestHelpers.makePaymentIntentAndElementsSession()

        var paymentSheetConfiguration = PaymentSheet.Configuration()
        paymentSheetConfiguration.cardBrandAcceptance = .all

        return PayWithLinkViewController.NewPaymentViewController(
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
            isAddingFirstPaymentMethod: isAddingFirstPaymentMethod
        )

    }
}
