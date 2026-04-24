//
//  PayWithLinkButtonTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class PayWithLinkButtonTests: XCTestCase {
    func testWalletHeaderViewStoresProvidedBrand() {
        let header = PaymentSheetViewController.WalletHeaderView(
            options: [.link],
            appearance: .default,
            linkBrand: .notlink,
            delegate: nil
        )

        XCTAssertEqual(header.linkBrand, .notlink)
    }

    func testBrandTintsPrimaryLinkLogoAsset() {
        let linkButton = PayWithLinkButton(brand: .link)
        let notlinkButton = PayWithLinkButton(brand: .notlink)

        XCTAssertNil(linkButton.primaryLinkLogoTintColor)
        XCTAssertEqual(notlinkButton.primaryLinkLogoTintColor, UIColor(red: 0.23, green: 0.74, blue: 0.66, alpha: 1.0))
        XCTAssertNotEqual(renderedPNGData(for: linkButton.primaryLinkLogoImage), renderedPNGData(for: notlinkButton.primaryLinkLogoImage))
    }

    func testBrandDoesNotChangeButtonStylingOutsideLogoTint() {
        let linkButton = PayWithLinkButton(brand: .link)
        let notlinkButton = PayWithLinkButton(brand: .notlink)

        linkButton.layoutIfNeeded()
        notlinkButton.layoutIfNeeded()

        XCTAssertEqual(notlinkButton.brand, .notlink)
        XCTAssertTrue(linkButton.backgroundColor?.isEqual(notlinkButton.backgroundColor) ?? false)
        XCTAssertEqual(linkButton.accessibilityLabel, notlinkButton.accessibilityLabel)
        XCTAssertEqual(linkButton.intrinsicContentSize, notlinkButton.intrinsicContentSize)
    }

    private func renderedPNGData(for image: UIImage) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.pngData { _ in
            image.draw(at: .zero)
        }
    }
}
