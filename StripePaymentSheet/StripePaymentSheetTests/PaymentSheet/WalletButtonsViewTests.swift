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
            merchantLogoUrl: nil,
            linkSettings: nil,
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: nil,
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
            passiveCaptchaData: nil,
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

        // Verify order is same as server ordering
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
            merchantLogoUrl: nil,
            linkSettings: nil,
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: nil,
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
            passiveCaptchaData: nil,
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
            merchantLogoUrl: nil,
            linkSettings: nil,
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: nil,
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
            passiveCaptchaData: nil,
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

    func testLinkRespectsOrderInPaymentMethodMode() {
        // Create mock elements session with Link ordered after Apple Pay and Shop Pay
        let elementsSession = STPElementsSession(
            allResponseFields: [:],
            sessionID: "test_session",
            orderedPaymentMethodTypes: [.card, .link],
            orderedPaymentMethodTypesAndWallets: ["apple_pay", "shop_pay", "link"],
            unactivatedPaymentMethodTypes: [],
            countryCode: nil,
            merchantCountryCode: nil,
            merchantLogoUrl: nil,
            linkSettings: nil,
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: nil,
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
            passiveCaptchaData: nil,
            customer: nil
        )

        // Create mock flow controller
        var psConfig = PaymentSheet.Configuration()
        psConfig.applePay = .init(merchantId: "test_merchant_id", merchantCountryCode: "US")
        psConfig.shopPay = PaymentSheet.ShopPayConfiguration(
            billingAddressRequired: false,
            emailRequired: false,
            shippingAddressRequired: false,
            lineItems: [],
            shippingRates: [],
            shopId: "test_shop_123",
            allowedShippingCountries: ["US"]
        )
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "usd", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil)) { _, _, _ in }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [])
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: psConfig)
        let flowController = PaymentSheet.FlowController(configuration: psConfig, loadResult: loadResult, analyticsHelper: analyticsHelper)

        // Initialize wallet buttons view
        let view = WalletButtonsView(flowController: flowController) { _ in }

        // Verify Link appears like in server ordering
        XCTAssertEqual(view.orderedWallets, [.applePay, .shopPay, .link])
    }

    func testLinkIsAppendedInPassthroughMode() {
        // Create mock elements session with Link ordered after Apple Pay and Shop Pay
        let elementsSession = STPElementsSession(
            allResponseFields: [:],
            sessionID: "test_session",
            orderedPaymentMethodTypes: [.card],
            orderedPaymentMethodTypesAndWallets: ["apple_pay", "shop_pay"],
            unactivatedPaymentMethodTypes: [],
            countryCode: nil,
            merchantCountryCode: nil,
            merchantLogoUrl: nil,
            linkSettings: LinkSettings._testValue(),
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: nil,
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
            passiveCaptchaData: nil,
            customer: nil
        )

        // Create mock flow controller
        var psConfig = PaymentSheet.Configuration()
        psConfig.applePay = .init(merchantId: "test_merchant_id", merchantCountryCode: "US")
        psConfig.shopPay = PaymentSheet.ShopPayConfiguration(
            billingAddressRequired: false,
            emailRequired: false,
            shippingAddressRequired: false,
            lineItems: [],
            shippingRates: [],
            shopId: "test_shop_123",
            allowedShippingCountries: ["US"]
        )
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "usd", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil)) { _, _, _ in }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [])
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: psConfig)
        let flowController = PaymentSheet.FlowController(configuration: psConfig, loadResult: loadResult, analyticsHelper: analyticsHelper)

        // Initialize wallet buttons view
        let view = WalletButtonsView(flowController: flowController) { _ in }

        // Verify Link is appended
        XCTAssertEqual(view.orderedWallets, [.applePay, .shopPay, .link])
    }

    func testLinkNotShownWhenDisabled() {
        // Create mock elements session with Link in ordering but Link disabled
        let elementsSession = STPElementsSession(
            allResponseFields: [:],
            sessionID: "test_session",
            orderedPaymentMethodTypes: [.card], // Link not in payment method types
            orderedPaymentMethodTypesAndWallets: ["apple_pay", "link", "shop_pay"],
            unactivatedPaymentMethodTypes: [],
            countryCode: nil,
            merchantCountryCode: nil,
            merchantLogoUrl: nil,
            linkSettings: nil,
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: nil,
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
            passiveCaptchaData: nil,
            customer: nil
        )

        // Create mock flow controller
        var psConfig = PaymentSheet.Configuration()
        psConfig.applePay = .init(merchantId: "test_merchant_id", merchantCountryCode: "US")
        psConfig.shopPay = PaymentSheet.ShopPayConfiguration(
            billingAddressRequired: false,
            emailRequired: false,
            shippingAddressRequired: false,
            lineItems: [],
            shippingRates: [],
            shopId: "test_shop_123",
            allowedShippingCountries: ["US"]
        )
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "usd", setupFutureUsage: nil, captureMethod: .automatic, paymentMethodOptions: nil)) { _, _, _ in }
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let loadResult = PaymentSheetLoader.LoadResult(intent: intent, elementsSession: elementsSession, savedPaymentMethods: [], paymentMethodTypes: [])
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: psConfig)
        let flowController = PaymentSheet.FlowController(configuration: psConfig, loadResult: loadResult, analyticsHelper: analyticsHelper)

        // Initialize wallet buttons view
        let view = WalletButtonsView(flowController: flowController) { _ in }

        // Verify Link is not shown when disabled, other wallets maintain order
        XCTAssertEqual(view.orderedWallets, [.applePay, .shopPay])
    }

    func testClickHandlerInvokedWithCorrectExpressType() {
        // Create mock elements session with Link and Apple Pay
        let elementsSession = STPElementsSession(
            allResponseFields: [:],
            sessionID: "test_session",
            orderedPaymentMethodTypes: [.card, .link],
            orderedPaymentMethodTypesAndWallets: ["apple_pay", "link"],
            unactivatedPaymentMethodTypes: [],
            countryCode: nil,
            merchantCountryCode: nil,
            merchantLogoUrl: nil,
            linkSettings: nil,
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: nil,
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
            passiveCaptcha: nil,
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

        var capturedWalletType: String?
        let clickHandler: WalletButtonsView.WalletButtonClickHandler = { walletType in
            capturedWalletType = walletType
            return true
        }

        // Initialize wallet buttons view with click handler
        let view = WalletButtonsView(flowController: flowController, confirmHandler: { _ in }, clickHandler: clickHandler)

        // Simulate button tap
        view.checkoutTapped(.applePay)

        // Verify handler was called with correct wallet type string
        XCTAssertEqual(capturedWalletType, "apple_pay")
    }

    func testClickHandlerReturningTrueAllowsCheckout() {
        // Create mock elements session with Link and Apple Pay
        let elementsSession = STPElementsSession(
            allResponseFields: [:],
            sessionID: "test_session",
            orderedPaymentMethodTypes: [.card, .link],
            orderedPaymentMethodTypesAndWallets: ["apple_pay", "link"],
            unactivatedPaymentMethodTypes: [],
            countryCode: nil,
            merchantCountryCode: nil,
            merchantLogoUrl: nil,
            linkSettings: nil,
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: nil,
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
            passiveCaptcha: nil,
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

        var handlerWasCalled = false
        var confirmHandlerWasCalled = false

        let clickHandler: WalletButtonsView.WalletButtonClickHandler = { _ in
            handlerWasCalled = true
            return true
        }

        // Initialize wallet buttons view with click handler
        let view = WalletButtonsView(flowController: flowController, confirmHandler: { _ in
            confirmHandlerWasCalled = true
        }, clickHandler: clickHandler)

        // Simulate button tap
        view.checkoutTapped(.applePay)

        // Verify handler was called
        XCTAssertTrue(handlerWasCalled)
        // Note: We can't reliably test if confirm was called since Apple Pay requires actual device capabilities
    }

    func testClickHandlerReturningFalseCancelsCheckout() {
        // Create mock elements session with Link and Apple Pay
        let elementsSession = STPElementsSession(
            allResponseFields: [:],
            sessionID: "test_session",
            orderedPaymentMethodTypes: [.card, .link],
            orderedPaymentMethodTypesAndWallets: ["apple_pay", "link"],
            unactivatedPaymentMethodTypes: [],
            countryCode: nil,
            merchantCountryCode: nil,
            merchantLogoUrl: nil,
            linkSettings: nil,
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: nil,
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
            passiveCaptcha: nil,
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

        var handlerWasCalled = false
        var confirmHandlerWasCalled = false

        let clickHandler: WalletButtonsView.WalletButtonClickHandler = { _ in
            handlerWasCalled = true
            return false // Cancel checkout
        }

        // Initialize wallet buttons view with click handler
        let view = WalletButtonsView(flowController: flowController, confirmHandler: { _ in
            confirmHandlerWasCalled = true
        }, clickHandler: clickHandler)

        // Simulate button tap
        view.checkoutTapped(.applePay)

        // Verify handler was called
        XCTAssertTrue(handlerWasCalled)
        // Verify confirm handler was NOT called (checkout was cancelled)
        XCTAssertFalse(confirmHandlerWasCalled)
    }

    func testNoClickHandlerAllowsNormalCheckout() {
        // Create mock elements session with Link and Apple Pay
        let elementsSession = STPElementsSession(
            allResponseFields: [:],
            sessionID: "test_session",
            orderedPaymentMethodTypes: [.card, .link],
            orderedPaymentMethodTypesAndWallets: ["apple_pay", "link"],
            unactivatedPaymentMethodTypes: [],
            countryCode: nil,
            merchantCountryCode: nil,
            merchantLogoUrl: nil,
            linkSettings: nil,
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: nil,
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
            passiveCaptcha: nil,
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

        // Initialize wallet buttons view WITHOUT click handler
        let view = WalletButtonsView(flowController: flowController, confirmHandler: { _ in })

        // Simulate button tap - should proceed normally without error
        view.checkoutTapped(.applePay)

        // Test passes if no error is thrown
    }
}
