//
//  ExpressCheckoutElementSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 7/27/26.
//

import StripeCoreTestUtils
@testable @_spi(STP) import StripePaymentSheet
import SwiftUI
import UIKit
import XCTest

@MainActor
final class ExpressCheckoutElementSnapshotTests: STPSnapshotTestCase {

    // MARK: - Default appearance

    func testDefaultAppearance_link() async throws {
        let view = try await makeExpressCheckoutElement(wallets: ["link"])
        verify(view)
    }

    func testDefaultAppearance_applePay() async throws {
        let view = try await makeExpressCheckoutElement(wallets: ["apple_pay"], includeApplePayConfig: true)
        verify(view)
    }

    func testDefaultAppearance_both() async throws {
        let view = try await makeExpressCheckoutElement(wallets: ["apple_pay", "link"], includeApplePayConfig: true)
        verify(view, height: 110)
    }

    // MARK: - Dark mode

    func testDarkMode_link() async throws {
        let view = try await makeExpressCheckoutElement(wallets: ["link"])
        verify(view, darkMode: true)
    }

    func testDarkMode_applePay() async throws {
        let view = try await makeExpressCheckoutElement(wallets: ["apple_pay"], includeApplePayConfig: true)
        verify(view, darkMode: true)
    }

    // MARK: - Custom appearance

    func testCustomCornerRadius() async throws {
        var appearance = ExpressCheckoutElement.Appearance()
        appearance.cornerRadius = 0
        let view = try await makeExpressCheckoutElement(wallets: ["link"], appearance: appearance)
        verify(view)
    }

    func testCustomButtonHeight() async throws {
        var appearance = ExpressCheckoutElement.Appearance()
        appearance.buttonHeight = 56
        let view = try await makeExpressCheckoutElement(wallets: ["link"], appearance: appearance)
        verify(view, height: 72)
    }

    func testCustomButtonSpacing() async throws {
        var appearance = ExpressCheckoutElement.Appearance()
        appearance.buttonSpacing = 16
        let view = try await makeExpressCheckoutElement(wallets: ["apple_pay", "link"], includeApplePayConfig: true, appearance: appearance)
        verify(view, height: 120)
    }

    // MARK: - Helpers

    @MainActor
    private func makeExpressCheckoutElement(
        wallets: [String],
        includeApplePayConfig: Bool = false,
        appearance: ExpressCheckoutElement.Appearance = .init()
    ) async throws -> some View {
        let session = makeSession(wallets: wallets)
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        configuration.expressCheckoutElement.appearance = appearance
        if includeApplePayConfig {
            configuration.applePayConfiguration = Checkout.ApplePayConfiguration(
                merchantId: "merchant.com.stripe.paymentsheet.example"
            )
        }
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeConfiguration(
                apiResponse: session,
                configuration: configuration
            )
        )
        return checkout.getExpressCheckoutElement().view
            .frame(width: 320)
            .ignoresSafeArea()
    }

    private func makeSession(wallets: [String]) -> PaymentPagesAPIResponse {
        let elementsSession: [String: Any] = [
            "session_id": "es_test",
            "payment_method_preference": ["ordered_payment_method_types": ["card"]],
            "ordered_payment_method_types_and_wallets": wallets,
        ]
        return CheckoutTestHelpers.makeSession(["elements_session": elementsSession])
    }

    private func verify(
        _ swiftUIView: some View,
        darkMode: Bool = false,
        height: CGFloat = 60,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let vc = UIHostingController(rootView: swiftUIView)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.overrideUserInterfaceStyle = darkMode ? .dark : .light
        window.rootViewController = vc
        window.makeKeyAndVisible()
        vc.view.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: height))

        STPSnapshotVerifyView(vc.view, file: file, line: line)
    }
}
