//
//  VerticalPaymentSheetViewControllerSnapshotTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 5/20/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

final class VerticalPaymentSheetViewControllerSnapshotTest: STPSnapshotTestCase {
    override func setUp() {
        super.setUp()
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testDisplaysFormDirectly() {
        // If there are no saved payment methods and we have only one payment method and it collects user input, display the form instead of the payment method list.
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            savedPaymentMethods: [],
            isLinkEnabled: false,
            isApplePayEnabled: false
        )
        verify(with: loadResult)
    }
    
    func testMultiplePaymentMethodTypes_withWallet() {
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            savedPaymentMethods: [],
            isLinkEnabled: true,
            isApplePayEnabled: true
        )
        verify(with: loadResult)
    }
    
    private func verify(with loadResult: PaymentSheetLoader.LoadResult, isFlowController: Bool = false) {
        let sut = PaymentSheetVerticalViewController(configuration: .init(), loadResult: loadResult, isFlowController: isFlowController)
        let bottomSheet = BottomSheetViewController(contentViewController: sut, appearance: .default, isTestMode: false, didCancelNative3DS2: {})
        let height = bottomSheet.view.systemLayoutSizeFitting(.init(width: 375, height: UIView.noIntrinsicMetric)).height
        bottomSheet.view.frame = .init(origin: .zero, size: .init(width: 375, height: height))
        STPSnapshotVerifyView(bottomSheet.view)
    }
}
