//
//  ShippingAddressViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
import StripePaymentsTestUtils
@_spi(STP) import StripeUICore
import XCTest

@testable@_spi(STP) import StripePaymentSheet

// @iOS26
final class ShippingAddressViewControllerSnapshotTests: STPSnapshotTestCase {

    override static func setUp() {
        if #available(iOS 26, *) {
            var configuration = PaymentSheet.Configuration()
            configuration.appearance.applyLiquidGlass()
            LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        }
    }

    func testWithSingleAddress() {
        let sut = makeSUT(shippingAddresses: Array(LinkStubs.shippingAddresses().prefix(1)))
        sut.loadViewIfNeeded()
        sut.viewWillAppear(false)
        verify(sut.view)
    }

    func testWithMultipleAddresses() {
        let sut = makeSUT(shippingAddresses: LinkStubs.shippingAddresses())
        sut.loadViewIfNeeded()
        sut.viewWillAppear(false)
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

extension ShippingAddressViewControllerSnapshotTests {

    func makeSUT(
        shippingAddresses: [ShippingAddressesResponse.ShippingAddress]
    ) -> PayWithLinkViewController.ShippingAddressViewController {
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
            paymentMethods: LinkStubs.paymentMethods(),
            shippingAddresses: shippingAddresses
        )

        return PayWithLinkViewController.ShippingAddressViewController(
            linkAccount: linkAccount,
            viewModel: viewModel,
            onAddressSelected: { _ in }
        )
    }
}
