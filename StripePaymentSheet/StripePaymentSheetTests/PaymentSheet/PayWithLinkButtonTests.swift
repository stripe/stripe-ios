//
//  PayWithLinkButtonTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit
import XCTest

final class PayWithLinkButtonTests: XCTestCase {
    func testEnabledStateUpdatesAccessibilityTraits() {
        for brand in [LinkBrand.link, .onelink] {
            // Given an enabled Link button displaying an account
            let button = PayWithLinkButton(brand: brand)
            button.linkAccount = makeAccount(email: "jenny@example.com")
            let label = button.accessibilityLabel
            XCTAssertEqual(button.accessibilityTraits, [.button])

            // When the button is disabled
            button.isEnabled = false

            // Then VoiceOver reports it as disabled without losing the account information
            XCTAssertEqual(button.accessibilityTraits, [.button, .notEnabled])
            XCTAssertEqual(button.accessibilityLabel, label)
            XCTAssertEqual(button.accessibilityValue, "jenny@example.com")

            // ...and enabling it removes the disabled trait
            button.isEnabled = true
            XCTAssertEqual(button.accessibilityTraits, [.button])
        }
    }

    func testCompactLayoutShowsOnlyLogoWithoutEmail() throws {
        for brand in [LinkBrand.link, .onelink] {
            // Given a signed-out ECE Link button
            let button = PayWithLinkButton(brand: brand)
            button.linkAccount = nil

            // When it shares a 320-point row with another wallet
            button.frame = CGRect(x: 0, y: 0, width: 156, height: 44)
            button.layoutIfNeeded()

            // Then only the complete, centered brand logo is visible
            let logo = try XCTUnwrap(findVisibleLogoImageView(in: button, matching: button.primaryLinkLogoImage))
            XCTAssertEqual(logo.center.x, button.bounds.midX, accuracy: 0.01)
            XCTAssertEqual(logo.center.y, button.bounds.midY, accuracy: 0.01)
            XCTAssertTrue(button.bounds.contains(logo.frame))
            XCTAssertTrue(visibleLabels(in: button).isEmpty)
            XCTAssertEqual(button.accessibilityLabel, brand == .link ? "Pay with Link" : "Pay with One-link")
            XCTAssertNil(button.accessibilityValue)
        }
    }

    func testCompactLayoutShowsLinkMarkAndTruncatedEmail() throws {
        for brand in [LinkBrand.link, .onelink] {
            // Given a registered account with a long email
            let email = "this.is.a.very.long.email.address@example.com"
            let button = PayWithLinkButton(brand: brand)
            button.linkAccount = makeAccount(email: email)

            // When the ECE button is compact
            button.frame = CGRect(x: 0, y: 0, width: 156, height: 44)
            button.layoutIfNeeded()

            // Then the small Link mark leaves room for a tail-truncated email
            let mark = try XCTUnwrap(findVisibleLogoImageView(in: button, matching: Image.link_mark_bw.makeImage(template: false)))
            let label = try XCTUnwrap(visibleLabels(in: button).first)
            XCTAssertEqual(mark.bounds.size, CGSize(width: 16, height: 16))
            XCTAssertNil(findVisibleLogoImageView(in: button, matching: button.primaryLinkLogoImage))
            XCTAssertEqual(label.text, email)
            XCTAssertEqual(label.lineBreakMode, .byTruncatingTail)
            XCTAssertLessThan(label.bounds.width, label.intrinsicContentSize.width)
            XCTAssertGreaterThan(label.bounds.width, 0)
            XCTAssertTrue(button.bounds.contains(button.convert(label.bounds, from: label)))
            XCTAssertEqual(button.accessibilityValue, email)
        }
    }

    func testCompactLayoutRestoresFullContentWhenResized() throws {
        for email in [nil, "user@example.com"] {
            // Given a compact button
            let button = PayWithLinkButton()
            button.linkAccount = email.map { makeAccount(email: $0) }
            button.frame = CGRect(x: 0, y: 0, width: 156, height: 44)
            button.layoutIfNeeded()

            // When its container grows to the full-content width
            button.frame.size.width = 200
            button.layoutIfNeeded()

            // Then the email or Pay with Link content is restored
            let label = try XCTUnwrap(visibleLabels(in: button).first)
            if let email {
                XCTAssertEqual(label.text, email)
            } else {
                XCTAssertTrue(label.attributedText?.string.contains("Pay with") ?? false)
            }

            // ...and narrowing the button restores the compact content for that account state
            button.frame.size.width = 156
            button.layoutIfNeeded()
            if let email {
                XCTAssertEqual(visibleLabels(in: button).first?.text, email)
                XCTAssertNotNil(findVisibleLogoImageView(in: button, matching: Image.link_mark_bw.makeImage(template: false)))
            } else {
                XCTAssertTrue(visibleLabels(in: button).isEmpty)
            }
        }
    }

    private func makeAccount(email: String) -> LinkAccountStub {
        LinkAccountStub(
            email: email,
            redactedPhoneNumber: nil,
            isRegistered: true,
            sessionState: .verified,
            consumerSessionClientSecret: nil,
            linkSessionKey: nil
        )
    }

    private func visibleLabels(in view: UIView) -> [UILabel] {
        guard !view.isHidden else { return [] }
        if let label = view as? UILabel { return [label] }
        return view.subviews.flatMap { visibleLabels(in: $0) }
    }

    private struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
        let sessionState: PaymentSheetLinkAccount.SessionState
        let consumerSessionClientSecret: String?
        let linkSessionKey: String?
    }

    func testWalletHeaderViewUsesProvidedBrandForPayWithLinkButton() throws {
        let header = PaymentSheetViewController.WalletHeaderView(
            options: [.link],
            appearance: .default,
            linkBrand: .onelink,
            delegate: nil
        )

        let button = try XCTUnwrap(
            findPayWithLinkButton(in: header)
        )
        XCTAssertEqual(button.accessibilityLabel, "Pay with One-link")
    }

    func testBrandUsesDistinctPrimaryLinkLogoAsset() {
        let linkButton = PayWithLinkButton(brand: .link)
        let onelinkButton = PayWithLinkButton(brand: .onelink)

        XCTAssertNotEqual(renderedPNGData(for: linkButton.primaryLinkLogoImage), renderedPNGData(for: onelinkButton.primaryLinkLogoImage))
    }

    func testBrandDoesNotChangeButtonStylingOutsideLogoImage() {
        let linkButton = PayWithLinkButton(brand: .link)
        let onelinkButton = PayWithLinkButton(brand: .onelink)

        linkButton.layoutIfNeeded()
        onelinkButton.layoutIfNeeded()

        XCTAssertEqual(onelinkButton.brand, .onelink)
        XCTAssertTrue(linkButton.backgroundColor?.isEqual(onelinkButton.backgroundColor) ?? false)
        XCTAssertEqual(linkButton.intrinsicContentSize, onelinkButton.intrinsicContentSize)
    }

    func testBrandUpdatesAccessibilityLabel() {
        let linkButton = PayWithLinkButton(brand: .link)
        let onelinkButton = PayWithLinkButton(brand: .onelink)

        XCTAssertEqual(linkButton.accessibilityLabel, "Pay with Link")
        XCTAssertEqual(onelinkButton.accessibilityLabel, "Pay with One-link")
    }

    func testOnelinkButtonReplacesBrandTextWithLogoAttachment() throws {
        let onelinkButton = PayWithLinkButton(brand: .onelink)
        onelinkButton.frame = CGRect(origin: .zero, size: CGSize(width: 240, height: 44))
        onelinkButton.layoutIfNeeded()

        let label = try XCTUnwrap(findVisibleAttributedLabel(in: onelinkButton))
        let renderedString = label.attributedText?.string ?? ""

        XCTAssertFalse(renderedString.contains(LinkBrand.link.displayName))
        XCTAssertFalse(renderedString.contains(LinkBrand.onelink.displayName))
        XCTAssertTrue(renderedString.contains("\u{FFFC}"))
    }

    func testLocalizedBrandStrings_useProvidedBrandDisplayName() {
        XCTAssertEqual(String.Localized.pay_with_link(brand: .link), "Pay with Link")
        XCTAssertEqual(String.Localized.pay_with_link(brand: .onelink), "Pay with Onelink")
        XCTAssertEqual(String.Localized.link_subtitle_text, "Simple, secure one-click payments")
        XCTAssertEqual(
            String.Localized.pay_faster_everywhere_brand_is_accepted(brand: .link),
            "Pay faster everywhere Link is accepted."
        )
        XCTAssertEqual(
            String.Localized.pay_faster_everywhere_brand_is_accepted(brand: .onelink),
            "Pay faster everywhere Onelink is accepted."
        )
        XCTAssertEqual(
            String.Localized.save_my_info_for_faster_checkout(with: .onelink),
            "Save my info for faster checkout with Onelink"
        )
    }

    func testLoggedInStateSizesLogoViewToMatchBrandAsset() throws {
        let onelinkButton = PayWithLinkButton(brand: .onelink)
        onelinkButton.linkAccount = LinkAccountStub(
            email: "test@example.com",
            redactedPhoneNumber: nil,
            isRegistered: true,
            sessionState: .verified,
            consumerSessionClientSecret: nil,
            linkSessionKey: nil
        )

        onelinkButton.frame = CGRect(origin: .zero, size: CGSize(width: 240, height: 44))
        onelinkButton.layoutIfNeeded()

        let expectedWidth =
            PayWithLinkButton.Constants.logoSize.height
            * (onelinkButton.primaryLinkLogoImage.size.width / onelinkButton.primaryLinkLogoImage.size.height)
        let logoView = try XCTUnwrap(findVisibleLogoImageView(in: onelinkButton, matching: onelinkButton.primaryLinkLogoImage))

        XCTAssertEqual(logoView.bounds.height, PayWithLinkButton.Constants.logoSize.height)
        XCTAssertEqual(logoView.bounds.width, expectedWidth, accuracy: 0.01)
        XCTAssertGreaterThan(logoView.bounds.width, PayWithLinkButton.Constants.logoSize.width)
    }

    private func renderedPNGData(for image: UIImage) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.pngData { _ in
            image.draw(at: .zero)
        }
    }

    private func findVisibleLogoImageView(in view: UIView, matching image: UIImage) -> UIImageView? {
        if let imageView = view as? UIImageView,
           renderedPNGData(for: imageView.image ?? UIImage()) == renderedPNGData(for: image) {
            return imageView
        }

        for subview in view.subviews where !subview.isHidden {
            if let imageView = findVisibleLogoImageView(in: subview, matching: image) {
                return imageView
            }
        }

        return nil
    }

    private func findPayWithLinkButton(in view: UIView) -> PayWithLinkButton? {
        if let button = view as? PayWithLinkButton {
            return button
        }

        for subview in view.subviews {
            if let button = findPayWithLinkButton(in: subview) {
                return button
            }
        }

        return nil
    }

    private func findVisibleAttributedLabel(in view: UIView) -> UILabel? {
        if let label = view as? UILabel,
           !view.isHidden,
           label.attributedText != nil {
            return label
        }

        for subview in view.subviews where !subview.isHidden {
            if let label = findVisibleAttributedLabel(in: subview) {
                return label
            }
        }

        return nil
    }
}
