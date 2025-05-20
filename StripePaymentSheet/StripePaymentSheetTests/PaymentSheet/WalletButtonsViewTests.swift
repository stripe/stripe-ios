//
//  WalletButtonsViewTests.swift
//  StripePaymentSheetTests
//

import Foundation

@_spi(STP) @testable import StripePaymentSheet
import SwiftUI
import XCTest

@available(iOS 16.0, *)
class WalletButtonsViewTests: XCTestCase {
    func testWalletButtonsWithLinkAndApplePay() {
        // Create mock elements session with Link and Apple Pay
        let elementsSession = STPElementsSession(
            allResponseFields: [:],
            sessionID: "test_session",
            orderedPaymentMethodTypes: [.card, .link],
            orderedPaymentMethodTypesAndWallets: ["apple_pay", "link"],
            unactivatedPaymentMethodTypes: [],
            countryCode: nil,
            merchantCountryCode: nil,
            linkSettings: nil,
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: nil,
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
            customer: nil
        )

        // Create mock flow controller
        var psConfig = PaymentSheet.Configuration()
        psConfig.applePay = .init(merchantId: "test_merchant_id", merchantCountryCode: "US")
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "usd", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil)) { _, _, _ in }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [])
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: psConfig)
        let flowController = PaymentSheet.FlowController(configuration: psConfig, loadResult: loadResult, analyticsHelper: analyticsHelper)

        // Initialize wallet buttons view
        let view = WalletButtonsView(flowController: flowController) { _ in }

        // Verify ordered wallets contains both Link and Apple Pay in correct order
        XCTAssertEqual(view.orderedWallets, [.applePay, .link])
    }

    func testWalletButtonsWithLinkAndApplePayButApplePayDisabled() {
        // Create mock elements session with Link and Apple Pay
        let elementsSession = STPElementsSession(
            allResponseFields: [:],
            sessionID: "test_session",
            orderedPaymentMethodTypes: [.card, .link],
            orderedPaymentMethodTypesAndWallets: ["link", "apple_pay"],
            unactivatedPaymentMethodTypes: [],
            countryCode: nil,
            merchantCountryCode: nil,
            linkSettings: nil,
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: nil,
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
            customer: nil
        )

        // Create mock flow controller
        var psConfig = PaymentSheet.Configuration()
        // Don't set up Apple Pay
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "usd", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil)) { _, _, _ in }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [])
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: psConfig)
        let flowController = PaymentSheet.FlowController(configuration: psConfig, loadResult: loadResult, analyticsHelper: analyticsHelper)

        // Initialize wallet buttons view
        let view = WalletButtonsView(flowController: flowController) { _ in }

        // Verify ordered wallets contains only Link
        XCTAssertEqual(view.orderedWallets, [.link])
    }

    func testWalletButtonsWithNoSupportedPMs() {
        // Create mock elements session with Link and Apple Pay
        let elementsSession = STPElementsSession(
            allResponseFields: [:],
            sessionID: "test_session",
            orderedPaymentMethodTypes: [],
            orderedPaymentMethodTypesAndWallets: ["google_pay"], // inexplicably, the server only sends us google pay
            unactivatedPaymentMethodTypes: [],
            countryCode: nil,
            merchantCountryCode: nil,
            linkSettings: nil,
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: nil,
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
            customer: nil
        )

        // Create mock flow controller
        var psConfig = PaymentSheet.Configuration()
        // Don't set up Apple Pay
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "usd", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil)) { _, _, _ in }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [])
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: psConfig)
        let flowController = PaymentSheet.FlowController(configuration: psConfig, loadResult: loadResult, analyticsHelper: analyticsHelper)

        // Initialize wallet buttons view
        let view = WalletButtonsView(flowController: flowController) { _ in }

        // Verify ordered wallets is empty, as there are no supported PMs
        XCTAssertEqual(view.orderedWallets, [])
    }
}
