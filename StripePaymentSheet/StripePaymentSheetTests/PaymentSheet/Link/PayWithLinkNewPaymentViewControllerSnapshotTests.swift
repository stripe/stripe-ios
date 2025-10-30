//
//  PayWithLinkNewPaymentViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Jeremy Kelleher on 10/1/25.
//

import StripeCoreTestUtils

@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripeUICore

// @iOS26
class PayWithLinkNewPaymentViewControllerSnapshotTests: STPSnapshotTestCase {

    override func setUp() {

        super.setUp()

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

extension PayWithLinkNewPaymentViewControllerSnapshotTests {

    func makeSUT(isAddingFirstPaymentMethod: Bool) throws -> PayWithLinkViewController.NewPaymentViewController {

        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])

        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.linkPaymentMethodsOnly = true

        return PayWithLinkViewController.NewPaymentViewController(
            linkAccount: LinkStubs.account(),
            context: .init(
                intent: intent,
                elementsSession: ._testValue(intent: intent),
                configuration: config,
                shouldOfferApplePay: false,
                shouldFinishOnClose: false,
                canSkipWalletAfterVerification: false,
                initiallySelectedPaymentDetailsID: nil,
                callToAction: nil,
                analyticsHelper: ._testValue()
            ),
            isAddingFirstPaymentMethod: isAddingFirstPaymentMethod
        )

    }

}
