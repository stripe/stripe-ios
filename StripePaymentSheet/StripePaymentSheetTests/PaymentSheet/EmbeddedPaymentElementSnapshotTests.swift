//
//  EmbeddedPaymentElementSnapshotTests.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 10/16/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(EmbeddedPaymentElementPrivateBeta) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP) @testable import StripeUICore
import XCTest

class EmbeddedPaymentElementSnapshotTests: STPSnapshotTestCase, EmbeddedPaymentElementDelegate {
    var delegateDidUpdateHeightCalled: Bool = false
    var delegateDidUpdatePaymentOptionCalled: Bool = false
    func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
        self.delegateDidUpdateHeightCalled = true
    }

    func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
        self.delegateDidUpdatePaymentOptionCalled = true
    }

    lazy var configuration: EmbeddedPaymentElement.Configuration = {
        var config = EmbeddedPaymentElement.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        config.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        return config
    }()
    let paymentIntentConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD"), paymentMethodTypes: ["card"]) { _, _, _ in
        // These tests don't confirm, so this is unused
    }
    let setupIntentConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession), paymentMethodTypes: ["card", "us_bank_account"]) { _, _, _ in
        // These tests don't confirm, so this is unused
    }

    func testUpdateFromCardToCardAndUSBankAccount() async throws {
        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 300)

        let loadResult = await sut.update(intentConfiguration: setupIntentConfig)
        XCTAssertEqual(loadResult, .succeeded)
        sut.view.autosizeHeight(width: 300)

        STPSnapshotVerifyView(sut.view) // Should show US Bank and card
        XCTAssertTrue(delegateDidUpdateHeightCalled)
        XCTAssertFalse(delegateDidUpdatePaymentOptionCalled)
    }
}
