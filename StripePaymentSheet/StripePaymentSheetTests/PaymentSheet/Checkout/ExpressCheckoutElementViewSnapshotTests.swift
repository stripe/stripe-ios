//
//  ExpressCheckoutElementViewSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 9/21/26.
//

import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripeUICore
import UIKit

@MainActor
// @iOS26
final class ExpressCheckoutElementViewSnapshotTests: STPSnapshotTestCase {

    func testDefaultAppearance() {
        verify(makeView())
    }

    func testLightButtonTheme() {
        var appearance = ExpressCheckoutElement.Appearance()
        appearance.buttonTheme = .light

        verify(makeView(appearance: appearance))
    }

    func testDarkButtonTheme() {
        var appearance = ExpressCheckoutElement.Appearance()
        appearance.buttonTheme = .dark

        verify(makeView(appearance: appearance))
    }

    func testTwoColumnLayout() {
        var appearance = ExpressCheckoutElement.Appearance()
        appearance.buttonLayout.maxColumns = 2
        appearance.buttonLayout.maxRows = 1

        verify(makeView(appearance: appearance))
    }

    func testOneColumnOneRowLayout() {
        var appearance = ExpressCheckoutElement.Appearance()
        appearance.buttonLayout.maxColumns = 1
        appearance.buttonLayout.maxRows = 1

        verify(makeView(appearance: appearance))
    }

    func testOneRowLayout() {
        var appearance = ExpressCheckoutElement.Appearance()
        appearance.buttonLayout.maxRows = 1

        verify(makeView(appearance: appearance))
    }

    // MARK: - Helpers

    private func makeView(
        appearance: ExpressCheckoutElement.Appearance = .init()
    ) -> ExpressCheckoutElementUIView {
        var configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })
        configuration.applePayConfiguration = .init(merchantId: "merchant.com.example")
        configuration.appearance = appearance

        let view = ExpressCheckoutElementUIView(
            session: CheckoutTestHelpers.makeSessionWithWalletTypes(["link", "apple_pay"]).makePublicSession(),
            configuration: configuration,
            delegate: Delegate()
        )
        view.setNeedsLayout()
        view.layoutIfNeeded()
        return view
    }

    private func verify(
        _ view: ExpressCheckoutElementUIView,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 320)

        let window = UIWindow(frame: CGRect(origin: .zero, size: view.frame.size))
        window.isHidden = false
        window.addAndPinSubview(view)
        window.layoutIfNeeded()

        STPSnapshotVerifyView(view, file: file, line: line)
    }

    private final class Delegate: ExpressCheckoutElementDelegate {
        func expressCheckoutElementShouldConfirm(
            _ paymentMethod: ExpressCheckoutElement.PaymentMethod,
            presentationWindow: UIWindow?
        ) async -> CheckoutController.ConfirmResult {
            fatalError("Not used by snapshot tests")
        }
    }
}
