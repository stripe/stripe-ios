//
//  WalletButtonsViewSnapshotTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
@_spi(STP)@testable import StripePaymentSheet
@_spi(STP)@testable import StripePaymentsTestUtils
import SwiftUI
import UIKit

@MainActor
class WalletButtonsViewSnapshotTests: STPSnapshotTestCase {

    @available(iOS 16.0, *)
    func testWalletButtonsView() {
        let flowController = PaymentSheet.FlowController(configuration: ._testValue_MostPermissive(), loadResult: ._testValue(paymentMethodTypes: [], savedPaymentMethods: []), analyticsHelper: ._testValue())
        let WalletButtonsView = WalletButtonsView(
            flowController: flowController,
            confirmHandler: { _ in },
            orderedWallets: [.applePay, .link]
        )
        let vc = UIHostingController(rootView: WalletButtonsView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 926))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        // Shadow rendering isn't deterministic enough, give a slightly larger perPixelTolerance
        STPSnapshotVerifyView(vc.view, identifier: nil, file: #filePath, line: #line)
    }

    @available(iOS 16.0, *)
    func testWalletButtonsViewWithCustomHeight() {
        // Create a configuration with custom primary button height
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.appearance.primaryButton.height = 60

        let flowController = PaymentSheet.FlowController(configuration: config, loadResult: ._testValue(paymentMethodTypes: [], savedPaymentMethods: []), analyticsHelper: ._testValue())
        let WalletButtonsView = WalletButtonsView(
            flowController: flowController,
            confirmHandler: { _ in },
            orderedWallets: [.applePay, .link]
        )
        let vc = UIHostingController(rootView: WalletButtonsView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 926))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        // Shadow rendering isn't deterministic enough, give a slightly larger perPixelTolerance
        STPSnapshotVerifyView(vc.view, identifier: "custom_height_60", file: #filePath, line: #line)
    }

    @available(iOS 16.0, *)
    func testWalletButtonsViewWithTallHeight() {
        // Create a configuration with tall primary button height
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.appearance.primaryButton.height = 80

        let flowController = PaymentSheet.FlowController(configuration: config, loadResult: ._testValue(paymentMethodTypes: [], savedPaymentMethods: []), analyticsHelper: ._testValue())
        let WalletButtonsView = WalletButtonsView(
            flowController: flowController,
            confirmHandler: { _ in },
            orderedWallets: [.applePay, .link]
        )
        let vc = UIHostingController(rootView: WalletButtonsView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 926))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        // Shadow rendering isn't deterministic enough, give a slightly larger perPixelTolerance
        STPSnapshotVerifyView(vc.view, identifier: "custom_height_80", file: #filePath, line: #line)
    }

    @available(iOS 16.0, *)
    func testWalletButtonsViewWithLinkEmail() {
        // Set up a Link account with email
        let linkAccount = PaymentSheetLinkAccount._testValue(email: "user@example.com", isRegistered: true)
        LinkAccountContext.shared.account = linkAccount

        let flowController = PaymentSheet.FlowController(configuration: ._testValue_MostPermissive(), loadResult: ._testValue(paymentMethodTypes: [], savedPaymentMethods: []), analyticsHelper: ._testValue())
        let WalletButtonsView = WalletButtonsView(
            flowController: flowController,
            confirmHandler: { _ in },
            orderedWallets: [.applePay, .link]
        )
        let vc = UIHostingController(rootView: WalletButtonsView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 926))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        // Shadow rendering isn't deterministic enough, give a slightly larger perPixelTolerance
        STPSnapshotVerifyView(vc.view, identifier: "link_with_email", file: #filePath, line: #line)

        // Clean up
        LinkAccountContext.shared.account = nil
    }

    @available(iOS 16.0, *)
    func testWalletButtonsViewWithLinkEmailTallHeight() {
        // Set up a Link account with email
        let linkAccount = PaymentSheetLinkAccount._testValue(email: "user@example.com", isRegistered: true)
        LinkAccountContext.shared.account = linkAccount

        // Create a configuration with tall primary button height
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.appearance.primaryButton.height = 80

        let flowController = PaymentSheet.FlowController(configuration: config, loadResult: ._testValue(paymentMethodTypes: [], savedPaymentMethods: []), analyticsHelper: ._testValue())
        let WalletButtonsView = WalletButtonsView(
            flowController: flowController,
            confirmHandler: { _ in },
            orderedWallets: [.applePay, .link]
        )
        let vc = UIHostingController(rootView: WalletButtonsView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 926))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        // Shadow rendering isn't deterministic enough, give a slightly larger perPixelTolerance
        STPSnapshotVerifyView(vc.view, identifier: "link_with_email_tall_height", file: #filePath, line: #line)

        // Clean up
        LinkAccountContext.shared.account = nil
    }

    // MARK: - ShopPay Tests

    @available(iOS 16.0, *)
    func testWalletButtonsViewWithShopPay() {
        // Create a configuration with ShopPay enabled
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.shopPay = PaymentSheet.ShopPayConfiguration(
            shippingAddressRequired: false,
            lineItems: [PaymentSheet.ShopPayConfiguration.LineItem(name: "Test Item", amount: 1000)],
            shippingRates: [],
            shopId: "test_shop_123"
        )
        config.customer = .init(id: "cus_123", customerSessionClientSecret: "cuss_123")

        let flowController = PaymentSheet.FlowController(configuration: config, loadResult: ._testValue(paymentMethodTypes: [], savedPaymentMethods: []), analyticsHelper: ._testValue())
        let WalletButtonsView = WalletButtonsView(
            flowController: flowController,
            confirmHandler: { _ in },
            orderedWallets: [.applePay, .link, .shopPay]
        )
        let vc = UIHostingController(rootView: WalletButtonsView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 926))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        // Shadow rendering isn't deterministic enough, give a slightly larger perPixelTolerance
        STPSnapshotVerifyView(vc.view, identifier: "with_shoppay", file: #filePath, line: #line)
    }

    @available(iOS 16.0, *)
    func testWalletButtonsViewWithShopPayCustomHeight() {
        // Create a configuration with ShopPay enabled and custom primary button height
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.shopPay = PaymentSheet.ShopPayConfiguration(
            shippingAddressRequired: false,
            lineItems: [PaymentSheet.ShopPayConfiguration.LineItem(name: "Test Item", amount: 1000)],
            shippingRates: [],
            shopId: "test_shop_123"
        )
        config.customer = .init(id: "cus_123", customerSessionClientSecret: "cuss_123")
        config.appearance.primaryButton.height = 60

        let flowController = PaymentSheet.FlowController(configuration: config, loadResult: ._testValue(paymentMethodTypes: [], savedPaymentMethods: []), analyticsHelper: ._testValue())
        let WalletButtonsView = WalletButtonsView(
            flowController: flowController,
            confirmHandler: { _ in },
            orderedWallets: [.applePay, .link, .shopPay]
        )
        let vc = UIHostingController(rootView: WalletButtonsView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 926))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        // Shadow rendering isn't deterministic enough, give a slightly larger perPixelTolerance
        STPSnapshotVerifyView(vc.view, identifier: "with_shoppay_custom_height_60", file: #filePath, line: #line)
    }

    @available(iOS 16.0, *)
    func testWalletButtonsViewWithShopPayTallHeight() {
        // Create a configuration with ShopPay enabled and tall primary button height
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.shopPay = PaymentSheet.ShopPayConfiguration(
            shippingAddressRequired: false,
            lineItems: [PaymentSheet.ShopPayConfiguration.LineItem(name: "Test Item", amount: 1000)],
            shippingRates: [],
            shopId: "test_shop_123"
        )
        config.customer = .init(id: "cus_123", customerSessionClientSecret: "cuss_123")
        config.appearance.primaryButton.height = 80

        let flowController = PaymentSheet.FlowController(configuration: config, loadResult: ._testValue(paymentMethodTypes: [], savedPaymentMethods: []), analyticsHelper: ._testValue())
        let WalletButtonsView = WalletButtonsView(
            flowController: flowController,
            confirmHandler: { _ in },
            orderedWallets: [.applePay, .link, .shopPay]
        )
        let vc = UIHostingController(rootView: WalletButtonsView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 926))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        // Shadow rendering isn't deterministic enough, give a slightly larger perPixelTolerance
        STPSnapshotVerifyView(vc.view, identifier: "with_shoppay_custom_height_80", file: #filePath, line: #line)
    }

    @available(iOS 16.0, *)
    func testWalletButtonsViewWithCustomCornerRadius() {
        // Create a configuration with custom corner radius
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.shopPay = PaymentSheet.ShopPayConfiguration(
            shippingAddressRequired: false,
            lineItems: [PaymentSheet.ShopPayConfiguration.LineItem(name: "Test Item", amount: 1000)],
            shippingRates: [],
            shopId: "test_shop_123"
        )
        config.customer = .init(id: "cus_123", customerSessionClientSecret: "cuss_123")
        config.appearance.cornerRadius = 12.0

        let flowController = PaymentSheet.FlowController(configuration: config, loadResult: ._testValue(paymentMethodTypes: [], savedPaymentMethods: []), analyticsHelper: ._testValue())
        let WalletButtonsView = WalletButtonsView(
            flowController: flowController,
            confirmHandler: { _ in },
            orderedWallets: [.applePay, .link, .shopPay]
        )
        let vc = UIHostingController(rootView: WalletButtonsView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 926))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        // Shadow rendering isn't deterministic enough, give a slightly larger perPixelTolerance
        STPSnapshotVerifyView(vc.view, identifier: "custom_corner_radius", file: #filePath, line: #line)
    }

    @available(iOS 16.0, *)
    func testWalletButtonsViewWithPrimaryButtonCornerRadius() {
        // Create a configuration with custom primary button corner radius (overrides general corner radius)
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.shopPay = PaymentSheet.ShopPayConfiguration(
            shippingAddressRequired: false,
            lineItems: [PaymentSheet.ShopPayConfiguration.LineItem(name: "Test Item", amount: 1000)],
            shippingRates: [],
            shopId: "test_shop_123"
        )
        config.customer = .init(id: "cus_123", customerSessionClientSecret: "cuss_123")
        config.appearance.cornerRadius = 6.0
        config.appearance.primaryButton.cornerRadius = 16.0

        let flowController = PaymentSheet.FlowController(configuration: config, loadResult: ._testValue(paymentMethodTypes: [], savedPaymentMethods: []), analyticsHelper: ._testValue())
        let WalletButtonsView = WalletButtonsView(
            flowController: flowController,
            confirmHandler: { _ in },
            orderedWallets: [.applePay, .link, .shopPay]
        )
        let vc = UIHostingController(rootView: WalletButtonsView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 926))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        // Shadow rendering isn't deterministic enough, give a slightly larger perPixelTolerance
        STPSnapshotVerifyView(vc.view, identifier: "primary_button_corner_radius", file: #filePath, line: #line)
    }
}
