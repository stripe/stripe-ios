//
//  PaymentSheetReloadTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 7/2/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import XCTest

@MainActor
final class PaymentSheetReloadTests: XCTestCase {
    override func setUpWithError() throws {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func makeLoadResult(
        orientation: PaymentSheet.PaymentMethodLayout.ResolvedLayout,
        savedPaymentMethods: [STPPaymentMethod] = []
    ) -> PaymentSheetLoader.LoadResult {
        return .init(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: nil,
            paymentMethodOrientation: orientation
        )
    }

    func makeVerticalViewController() -> PaymentSheetVerticalViewController {
        let vc = PaymentSheetVerticalViewController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeLoadResult(orientation: .vertical),
            isFlowController: true,
            analyticsHelper: ._testValue()
        )
        _ = vc.view
        return vc
    }

    func makeHorizontalViewController() -> PaymentSheetFlowControllerViewController {
        let vc = PaymentSheetFlowControllerViewController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeLoadResult(orientation: .horizontal),
            analyticsHelper: ._testValue()
        )
        _ = vc.view
        return vc
    }

}
