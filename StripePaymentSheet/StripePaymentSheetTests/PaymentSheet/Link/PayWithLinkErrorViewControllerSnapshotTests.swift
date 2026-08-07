//
//  PayWithLinkErrorViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils

@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripeUICore

// @iOS26
class PayWithLinkErrorViewControllerSnapshotTests: STPSnapshotTestCase {

    override func setUp() {
        super.setUp()

        if #available(iOS 26, *) {
            var configuration = PaymentSheet.Configuration()
            configuration.appearance.applyLiquidGlass()
            LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        }
    }

    func testCanContinueWithoutLink() throws {
        let sut = try makeSUT(canContinueWithoutLink: true)
        verify(sut)
    }

    func testCannotContinueWithoutLink() throws {
        let sut = try makeSUT(canContinueWithoutLink: false)
        verify(sut)
    }

    func verify(
        _ element: PayWithLinkViewController.ErrorViewController,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        element.view.autosizeHeight(width: 340)
        STPSnapshotVerifyView(element.view, identifier: identifier, file: file, line: line)
    }
}

extension PayWithLinkErrorViewControllerSnapshotTests {

    func makeSUT(canContinueWithoutLink: Bool) throws -> PayWithLinkViewController.ErrorViewController {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let config = PaymentSheet.Configuration._testValue_MostPermissive()

        return PayWithLinkViewController.ErrorViewController(
            context: .init(
                intent: intent,
                elementsSession: ._testValue(intent: intent),
                configuration: config,
                linkBrand: .link,
                shouldOfferApplePay: false,
                shouldFinishOnClose: false,
                canContinueWithoutLink: canContinueWithoutLink,
                initiallySelectedPaymentDetailsID: nil,
                callToAction: nil,
                analyticsHelper: ._testValue()
            )
        )
    }
}
