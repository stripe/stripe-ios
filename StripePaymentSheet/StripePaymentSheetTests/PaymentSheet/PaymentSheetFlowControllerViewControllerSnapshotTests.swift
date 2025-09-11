//
//  PaymentSheetFlowControllerViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 9/7/23.
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore

import XCTest

// @iOS26
final class PaymentSheetFlowControllerViewControllerSnapshotTests: STPSnapshotTestCase {
    func makeTestLoadResult(savedPaymentMethods: [STPPaymentMethod]) -> PaymentSheetLoader.LoadResult {
        return .init(
            intent: ._testValue(),
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: false),
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: [.stripe(.card)]
        )
    }

    func testSavedScreen_card() {
        let paymentMethods = [
            STPPaymentMethod._testCard(),
        ]
        let sut = PaymentSheetFlowControllerViewController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeTestLoadResult(savedPaymentMethods: paymentMethods),
            analyticsHelper: ._testValue()
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testSavedScreen_us_bank_account() {
        let paymentMethods = [
            STPPaymentMethod._testUSBankAccount(),
        ]
        let sut = PaymentSheetFlowControllerViewController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeTestLoadResult(savedPaymentMethods: paymentMethods),
            analyticsHelper: ._testValue()
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testSavedScreen_SEPA_debit() {
        let paymentMethods = [
            STPPaymentMethod._testSEPA(),
        ]
        let sut = PaymentSheetFlowControllerViewController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: makeTestLoadResult(savedPaymentMethods: paymentMethods),
            analyticsHelper: ._testValue()
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testSavedScreen_customCTA() {
        let paymentMethods = [
            STPPaymentMethod._testSEPA(),
        ]
        var configuration: PaymentSheet.Configuration = ._testValue_MostPermissive(isApplePayEnabled: false)
        configuration.primaryButtonLabel = "Submit"
        let sut = PaymentSheetFlowControllerViewController(
            configuration: configuration,
            loadResult: makeTestLoadResult(savedPaymentMethods: paymentMethods),
            analyticsHelper: ._testValue()
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testNewScreen_customCTA() {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)

        var configuration: PaymentSheet.Configuration = ._testValue_MostPermissive(isApplePayEnabled: false)
        configuration.primaryButtonLabel = "Submit"
        let sut = PaymentSheetFlowControllerViewController(
            configuration: configuration,
            loadResult: makeTestLoadResult(savedPaymentMethods: []),
            analyticsHelper: ._testValue()
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testDirectToCardScan() {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)

        var configuration: PaymentSheet.Configuration = PaymentSheet.Configuration()
        configuration.returnURL = "https://foo.com"
        configuration.opensCardScannerAutomatically = true
        configuration.appearance.applyingLiquidGlassIfPossible()

        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testValue(),
            elementsSession: ._testValue(
                paymentMethodTypes: ["card"],
                isLinkPassthroughModeEnabled: false
            ),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)]
        )

        let sut = PaymentSheetFlowControllerViewController(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue()
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }
}
