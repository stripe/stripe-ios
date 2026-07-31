//
//  AddShippingAddressViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
import StripePaymentsTestUtils
@_spi(STP) import StripeUICore
import XCTest

@testable@_spi(STP) import StripePaymentSheet

// @iOS26
final class AddShippingAddressViewControllerSnapshotTests: STPSnapshotTestCase {

    override func setUp() {
        super.setUp()

        if #available(iOS 26, *) {
            var configuration = PaymentSheet.Configuration()
            configuration.appearance.applyLiquidGlass()
            LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        }

        let expectation = expectation(description: "Load address specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testDefault() {
        let sut = makeSUT()
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

extension AddShippingAddressViewControllerSnapshotTests {

    func makeSUT() -> PayWithLinkViewController.AddShippingAddressViewController {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        var configuration = PaymentSheet.Configuration()
        configuration.allowsPaymentMethodsRequiringShippingAddress = true

        let linkAccount = LinkStubs.account()
        let context = PayWithLinkViewController.Context(
            intent: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: configuration,
            linkBrand: .link,
            shouldOfferApplePay: false,
            shouldFinishOnClose: false,
            initiallySelectedPaymentDetailsID: nil,
            callToAction: nil,
            analyticsHelper: ._testValue()
        )
        let viewModel = PayWithLinkViewController.WalletViewModel(
            linkAccount: linkAccount,
            context: context,
            paymentMethods: []
        )

        return PayWithLinkViewController.AddShippingAddressViewController(
            linkAccount: linkAccount,
            viewModel: viewModel,
            onAddressCreated: { _ in }
        )
    }
}
