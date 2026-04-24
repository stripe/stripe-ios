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

    func testBrandUsesDistinctPrimaryLinkLogoAsset() {
        let linkButton = PayWithLinkButton(brand: .link)
        let notlinkButton = PayWithLinkButton(brand: .notlink)

        XCTAssertNotEqual(renderedPNGData(for: linkButton.primaryLinkLogoImage), renderedPNGData(for: notlinkButton.primaryLinkLogoImage))
    }

    func testBrandDoesNotChangeButtonStylingOutsideLogoImage() {
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
