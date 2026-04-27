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
    }

    private func renderedPNGData(for image: UIImage) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.pngData { _ in
            image.draw(at: .zero)
        }
    }
}
