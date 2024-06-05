//
//  PaymentSheetFlowControllerViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 9/7/23.
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @_spi(EarlyAccessCVCRecollectionFeature) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore

import XCTest

final class PaymentSheetFlowControllerViewControllerSnapshotTests: STPSnapshotTestCase {
    func makeTestLoadResult(paymentMethods: [STPPaymentMethod]) -> PaymentSheetLoader.LoadResult {
        return .init(
            intent: ._testValue(),
            savedPaymentMethods: paymentMethods,
            isLinkEnabled: false,
            isApplePayEnabled: false
        )
    }

    func testSavedScreen_card() {
        let paymentMethods = [
            STPPaymentMethod._testCard(),
        ]
        let sut = PaymentSheetFlowControllerViewController(
            configuration: ._testValue_MostPermissive(),
            loadResult: makeTestLoadResult(paymentMethods: paymentMethods)
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testSavedScreen_us_bank_account() {
        let paymentMethods = [
            STPPaymentMethod._testUSBankAccount(),
        ]
        let sut = PaymentSheetFlowControllerViewController(
            configuration: ._testValue_MostPermissive(),
            loadResult: makeTestLoadResult(paymentMethods: paymentMethods)
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testSavedScreen_SEPA_debit() {
        let paymentMethods = [
            STPPaymentMethod._testSEPA(),
        ]
        let sut = PaymentSheetFlowControllerViewController(
            configuration: ._testValue_MostPermissive(),
            loadResult: makeTestLoadResult(paymentMethods: paymentMethods)
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }
    func testCVCRecollectionScreen() {
        let configuration: PaymentSheet.Configuration = ._testValue_MostPermissive()

        let sut = PreConfirmationViewController(paymentMethod: STPPaymentMethod._testCard(),
                                                intent: ._testValue(),
                                                configuration: configuration,
                                                onCompletion: { _, _ in },
                                                onCancel: { _ in })
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testCVVRecollectionScreen() {
        let configuration: PaymentSheet.Configuration = ._testValue_MostPermissive()

        let sut = PreConfirmationViewController(paymentMethod: STPPaymentMethod._testCardAmex(),
                                                intent: ._testValue(),
                                                configuration: configuration,
                                                onCompletion: { _, _ in },
                                                onCancel: { _ in })
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testSavedScreen_customCTA() {
        let paymentMethods = [
            STPPaymentMethod._testSEPA(),
        ]
        var configuration: PaymentSheet.Configuration = ._testValue_MostPermissive()
        configuration.primaryButtonLabel = "Submit"
        let sut = PaymentSheetFlowControllerViewController(
            configuration: configuration,
            loadResult: makeTestLoadResult(paymentMethods: paymentMethods)
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

    func testNewScreen_customCTA() {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                PaymentMethodFormViewController.clearFormCache()
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)

        var configuration: PaymentSheet.Configuration = ._testValue_MostPermissive()
        configuration.primaryButtonLabel = "Submit"
        let sut = PaymentSheetFlowControllerViewController(
            configuration: configuration,
            loadResult: makeTestLoadResult(paymentMethods: [])
        )
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }

}
