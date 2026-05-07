//
//  LinkBrandTests.swift
//  StripeCoreTests
//

@_spi(STP) @testable import StripeCore
import XCTest

final class LinkBrandTests: XCTestCase {
    func testDisplayName_forLinkBrand() {
        XCTAssertEqual(LinkBrand.link.displayName, "Link")
    }

    func testDisplayName_forOnelinkBrand() {
        XCTAssertEqual(LinkBrand.onelink.displayName, "Onelink")
    }

    func testDisplayName_forUnparsableBrandFallsBackToLink() {
        XCTAssertEqual(LinkBrand.unparsable.displayName, "Link")
    }

    func testLegalURLs_forOnelinkBrand() {
        XCTAssertEqual(LinkBrand.onelink.websiteURL.absoluteString, "https://onelink.com")
        XCTAssertEqual(LinkBrand.onelink.checkoutURL.absoluteString, "https://checkout.onelink.com/")
        XCTAssertEqual(LinkBrand.onelink.termsURL.absoluteString, "https://onelink.com/terms")
        XCTAssertEqual(LinkBrand.onelink.privacyURL.absoluteString, "https://onelink.com/privacy")
        XCTAssertEqual(LinkBrand.onelink.achAuthorizationURL.absoluteString, "https://onelink.com/terms/ach-authorization")
        XCTAssertEqual(LinkBrand.onelink.promotionTermsURL.absoluteString, "https://onelink.com/promotion-terms")
        XCTAssertEqual(LinkBrand.onelink.supportContactURL.absoluteString, "https://support.onelink.com/contact/email?skipVerification=true")
    }

    func testBrandAwareLegalSupportURL_forOnelinkRewritesKnownLinkURLs() {
        XCTAssertEqual(
            LinkBrand.onelink.brandAwareLegalSupportURL(for: URL(string: "https://link.co/terms")!).absoluteString,
            "https://onelink.com/terms"
        )
        XCTAssertEqual(
            LinkBrand.onelink.brandAwareLegalSupportURL(for: URL(string: "https://support.link.co/questions/foo")!).absoluteString,
            "https://support.onelink.com/questions/foo"
        )
        XCTAssertEqual(
            LinkBrand.onelink.brandAwareLegalSupportURL(for: URL(string: "https://stripe.com/legal/end-users#linked-financial-account-terms")!).absoluteString,
            "https://onelink.com/terms#financial-connections-terms"
        )
    }

    func testBrandAwareLegalSupportURL_forLinkLeavesURLUnchanged() {
        let url = URL(string: "https://link.co/privacy")!
        XCTAssertEqual(LinkBrand.link.brandAwareLegalSupportURL(for: url), url)
        XCTAssertEqual(LinkBrand.unparsable.brandAwareLegalSupportURL(for: url), url)
    }
}
