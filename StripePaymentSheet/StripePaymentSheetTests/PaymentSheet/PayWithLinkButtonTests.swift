//
//  PayWithLinkButtonTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class PayWithLinkButtonTests: XCTestCase {
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

    func testPaymentMethodPreviewIsShownForRegisteredAccount() {
        // Given a registered account
        let button = PayWithLinkButton(brand: .link, observesLinkAccountContext: false)
        button.linkAccount = makeLinkAccount(isRegistered: true)

        // When a payment method preview is set
        let preview = LinkPaymentMethodPreview(icon: UIImage(), last4: "4242", accessibilityName: "Visa")
        button.paymentMethodPreview = preview

        // Then the button shows the payment method
        XCTAssertEqual(button.linkAccountState, .hasPaymentMethod(preview))
        XCTAssertEqual(button.accessibilityValue, "Visa 4242")
    }

    func testPaymentMethodPreviewIsIgnoredForUnregisteredAccount() {
        // Given an unregistered account
        let button = PayWithLinkButton(brand: .link, observesLinkAccountContext: false)
        button.linkAccount = makeLinkAccount(isRegistered: false)

        // When a payment method preview is set
        button.paymentMethodPreview = LinkPaymentMethodPreview(icon: UIImage(), last4: "4242", accessibilityName: "Visa")

        // Then the button stays logged out
        XCTAssertEqual(button.linkAccountState, .noValidAccount)
        XCTAssertNil(button.accessibilityValue)
    }

    func testRegisteredAccountWithoutPaymentMethodPreviewShowsEmail() {
        // Given a registered account and no payment method preview
        let button = PayWithLinkButton(brand: .link, observesLinkAccountContext: false)
        button.linkAccount = makeLinkAccount(isRegistered: true)

        // Then the button shows the email
        XCTAssertEqual(button.linkAccountState, .hasEmail(email: "test@example.com"))
        XCTAssertEqual(button.accessibilityValue, "test@example.com")
    }

    func testLogoFrameMatchesRenderedLogo() throws {
        for brand in [LinkBrand.link, .onelink] {
            for linkAccount in [nil, makeLinkAccount(isRegistered: true)] {
                // Given a button showing the Link logo
                let button = PayWithLinkButton(brand: brand, observesLinkAccountContext: false)
                button.linkAccount = linkAccount
                button.frame = CGRect(origin: .zero, size: CGSize(width: 260, height: 44))
                button.layoutIfNeeded()
                let state = button.linkAccountState

                // When the logo is hidden
                let imageWithLogo = renderedRGBAImage(of: button)
                button.setLogoHidden(true, for: state)
                let imageWithoutLogo = renderedRGBAImage(of: button)

                // Then the pixels that change are within the logo frame
                let renderedLogoFrame = try XCTUnwrap(differingRect(between: imageWithLogo, and: imageWithoutLogo))
                let logoFrame = try XCTUnwrap(button.logoFrame(for: state))
                let message = "\(brand) \(state)"
                XCTAssertEqual(renderedLogoFrame.minX, logoFrame.minX, accuracy: 1, message)
                XCTAssertEqual(renderedLogoFrame.maxX, logoFrame.maxX, accuracy: 1, message)
                XCTAssertEqual(renderedLogoFrame.minY, logoFrame.minY, accuracy: 1, message)
                XCTAssertEqual(renderedLogoFrame.maxY, logoFrame.maxY, accuracy: 1, message)
            }
        }
    }

    func testAnimatedStateChangeMovesLogoAndCleansUp() {
        // Given a logged out button on screen
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 100)))
        let button = PayWithLinkButton(brand: .link, observesLinkAccountContext: false)
        button.frame = CGRect(origin: .zero, size: CGSize(width: 260, height: 44))
        window.addSubview(button)
        button.layoutIfNeeded()
        let subviewCount = button.subviews.count

        // When the customer is recognized, with animation
        button.performStateChange(animated: true, duration: 0.25) {
            button.linkAccount = makeLinkAccount(isRegistered: true)
        }

        // Then a logo is added to move between the two layouts, and both layouts are on screen
        XCTAssertEqual(button.subviews.count, subviewCount + 1)
        XCTAssertEqual(button.subviews.filter { !$0.isHidden }.count, 3)

        // When the transition finishes
        button.finishStateTransition()

        // Then only the new layout remains
        XCTAssertEqual(button.subviews.count, subviewCount)
        let visibleSubviews = button.subviews.filter { !$0.isHidden }
        XCTAssertEqual(visibleSubviews.count, 1)
        XCTAssertEqual(visibleSubviews.first?.alpha, 1)
        XCTAssertEqual(button.linkAccountState, .hasEmail(email: "test@example.com"))
    }

    func testRedundantStateChangeDuringTransitionKeepsAnimating() {
        // Given an in-flight transition
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 100)))
        let button = PayWithLinkButton(brand: .link, observesLinkAccountContext: false)
        button.frame = CGRect(origin: .zero, size: CGSize(width: 260, height: 44))
        window.addSubview(button)
        button.layoutIfNeeded()
        let subviewCount = button.subviews.count
        let linkAccount = makeLinkAccount(isRegistered: true)
        button.performStateChange(animated: true, duration: 0.25) {
            button.linkAccount = linkAccount
        }

        // When the same state is applied again, as happens when several properties of the Link account are published
        button.performStateChange(animated: true, duration: 0.25) {
            button.brand = .link
            button.linkAccount = linkAccount
            button.paymentMethodPreview = nil
        }
        button.linkAccount = linkAccount

        // Then the transition keeps running
        XCTAssertEqual(button.subviews.count, subviewCount + 1)
        XCTAssertEqual(button.subviews.filter { !$0.isHidden }.count, 3)
    }

    func testStateChangeDuringTransitionFinishesTransition() {
        // Given an in-flight transition
        let window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 100)))
        let button = PayWithLinkButton(brand: .link, observesLinkAccountContext: false)
        button.frame = CGRect(origin: .zero, size: CGSize(width: 260, height: 44))
        window.addSubview(button)
        button.layoutIfNeeded()
        let subviewCount = button.subviews.count
        button.performStateChange(animated: true, duration: 0.25) {
            button.linkAccount = makeLinkAccount(isRegistered: true)
        }

        // When the customer logs out before it completes
        button.linkAccount = nil

        // Then the button shows only the logged out layout
        XCTAssertEqual(button.subviews.count, subviewCount)
        XCTAssertEqual(button.subviews.filter { !$0.isHidden }.count, 1)
        XCTAssertEqual(button.linkAccountState, .noValidAccount)
    }

    private struct RGBAImage {
        let width: Int
        let height: Int
        let scale: CGFloat
        let pixels: [UInt8]
    }

    private func renderedRGBAImage(of view: UIView, scale: CGFloat = 3) -> RGBAImage {
        let width = Int(view.bounds.width * scale)
        let height = Int(view.bounds.height * scale)
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        pixels.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            // Flip to UIKit's coordinate space
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: scale, y: -scale)
            view.layer.render(in: context)
        }
        return RGBAImage(width: width, height: height, scale: scale, pixels: pixels)
    }

    private func differingRect(between image: RGBAImage, and otherImage: RGBAImage) -> CGRect? {
        var minX = Int.max, minY = Int.max, maxX = Int.min, maxY = Int.min
        for y in 0..<image.height {
            for x in 0..<image.width {
                let offset = (y * image.width + x) * 4
                // Ignore anti-aliasing noise
                let difference = (0..<4).map { abs(Int(image.pixels[offset + $0]) - Int(otherImage.pixels[offset + $0])) }.max() ?? 0
                guard difference > 16 else { continue }
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
        guard minX <= maxX else {
            return nil
        }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
            .applying(CGAffineTransform(scaleX: 1 / image.scale, y: 1 / image.scale))
    }

    private func makeLinkAccount(isRegistered: Bool) -> LinkAccountStub {
        LinkAccountStub(
            email: "test@example.com",
            redactedPhoneNumber: nil,
            isRegistered: isRegistered,
            sessionState: isRegistered ? .verified : .requiresSignUp,
            consumerSessionClientSecret: nil,
            linkSessionKey: nil
        )
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
