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
}
