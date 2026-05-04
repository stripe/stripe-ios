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
    }

    func testWalletHeaderViewStoresProvidedBrand() {
        let header = PaymentSheetViewController.WalletHeaderView(
            options: [.link],
            appearance: .default,
            linkBrand: .onelink,
            delegate: nil
        )

        XCTAssertEqual(header.linkBrand, .onelink)
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
        XCTAssertEqual(linkButton.accessibilityLabel, onelinkButton.accessibilityLabel)
        XCTAssertEqual(linkButton.intrinsicContentSize, onelinkButton.intrinsicContentSize)
    }

    func testLoggedInStateSizesLogoViewToMatchBrandAsset() throws {
        let onelinkButton = PayWithLinkButton(brand: .onelink)
        onelinkButton.linkAccount = LinkAccountStub(
            email: "test@example.com",
            redactedPhoneNumber: nil,
            isRegistered: true,
            sessionState: .verified,
            consumerSessionClientSecret: nil
        )

        onelinkButton.frame = CGRect(origin: .zero, size: CGSize(width: 240, height: 44))
        onelinkButton.layoutIfNeeded()

        let expectedWidth = ceil(
            PayWithLinkButton.Constants.logoSize.height
                * (onelinkButton.primaryLinkLogoImage.size.width / onelinkButton.primaryLinkLogoImage.size.height)
        )
        let logoView = try XCTUnwrap(findVisibleLogoImageView(in: onelinkButton, matching: onelinkButton.primaryLinkLogoImage))

        XCTAssertEqual(logoView.bounds.height, PayWithLinkButton.Constants.logoSize.height)
        XCTAssertEqual(logoView.bounds.width, expectedWidth)
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
}
