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
import XCTest

@MainActor
// @iOS26
final class ExpressCheckoutElementViewSnapshotTests: STPSnapshotTestCase {

    // The default one-column layout displays Apple Pay and Link in two rows.
    func testDefaultTwoRowLayout() {
        verify(makeView())
    }

    func testLightButtonTheme() {
        var appearance = ExpressCheckoutElement.Configuration.Appearance()
        appearance.buttonTheme = .light

        verify(makeView(appearance: appearance))
    }

    func testDarkButtonTheme() {
        var appearance = ExpressCheckoutElement.Configuration.Appearance()
        appearance.buttonTheme = .dark

        verify(makeView(appearance: appearance))
    }

    func testTwoColumnLayout() {
        var appearance = ExpressCheckoutElement.Configuration.Appearance()
        appearance.buttonLayout.maxColumns = 2
        appearance.buttonLayout.maxRows = 1

        verify(makeView(appearance: appearance))
    }

    func testTwoColumnLayoutWithoutEmail() throws {
        try verifyCompactLayout(email: nil)
    }

    func testTwoColumnLayoutWithEmail() throws {
        try verifyCompactLayout(email: "this.is.a.very.long.email.address@example.com")
    }

    func testThreeButtonsInTwoByTwoGrid() {
        var appearance = ExpressCheckoutElement.Configuration.Appearance()
        appearance.buttonLayout.maxColumns = 2
        appearance.buttonLayout.maxRows = 2

        verify(makeView(
            appearance: appearance,
            buttons: [.link, .applePay, .link]
        ))
    }

    func testOneColumnOneRowLayout() {
        var appearance = ExpressCheckoutElement.Configuration.Appearance()
        appearance.buttonLayout.maxColumns = 1
        appearance.buttonLayout.maxRows = 1

        verify(makeView(appearance: appearance))
    }

    func testOneRowLayout() {
        var appearance = ExpressCheckoutElement.Configuration.Appearance()
        appearance.buttonLayout.maxRows = 1

        verify(makeView(appearance: appearance))
    }

    // MARK: - Helpers

    private func verifyCompactLayout(email: String?, file: StaticString = #filePath, line: UInt = #line) throws {
        var appearance = ExpressCheckoutElement.Configuration.Appearance()
        appearance.buttonLayout.maxColumns = 2
        appearance.buttonLayout.maxRows = 1
        let view = makeView(appearance: appearance, buttons: [.applePay, .link])
        let stackView = view.subviews.first as? UIStackView
        let row = stackView?.arrangedSubviews.first as? UIStackView
        let linkButton = try XCTUnwrap(row?.arrangedSubviews.last as? PayWithLinkButton)
        if let email {
            linkButton.linkAccount = LinkAccountStub(email: email)
        } else {
            linkButton.linkAccount = nil
        }
        verify(view, file: file, line: line)
    }

    private struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String? = nil
        let isRegistered = true
        let sessionState: PaymentSheetLinkAccount.SessionState = .verified
        let consumerSessionClientSecret: String? = nil
        let linkSessionKey: String? = nil
    }

    private func makeView(
        appearance: ExpressCheckoutElement.Configuration.Appearance = .init(),
        buttons: [ExpressCheckoutElement.PaymentMethod]? = nil
    ) -> ExpressCheckoutElementUIView {
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = .init(merchantId: "merchant.com.example")
        configuration.appearance = appearance

        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link", "apple_pay"], customerEmail: "jenny@example.com")
            .makePublicSession(expressCheckoutConfiguration: configuration)
        let view = ExpressCheckoutElementUIView(
            session: session,
            configuration: configuration,
            delegate: Delegate()
        )
        view.update(
            with: session,
            buttons: buttons ?? session.availableExpressCheckoutPaymentMethods.compactMap { ExpressCheckoutElement.PaymentMethod(rawValue: $0) }
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
