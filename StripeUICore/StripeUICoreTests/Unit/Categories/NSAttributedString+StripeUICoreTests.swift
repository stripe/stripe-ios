//
//  NSAttributedString+StripeUICoreTests.swift
//  StripeUICoreTests
//
//  Created by Nick Porter on 9/1/23.
//

@_spi(STP) @testable import StripeUICore
import XCTest

final class NSAttributedStringStripeUICoreTests: XCTestCase {

    func hasTextAttachment_shouldReturnTrue() {
        let brandImageAttachment = NSTextAttachment()
        brandImageAttachment.image = UIImage()

        let attrString = NSAttributedString(attachment: brandImageAttachment)
        XCTAssertTrue(attrString.hasTextAttachment)
    }

    func hasTextAttachment_shouldReturnFalse() {
        let attrString = NSAttributedString(string: "no text attachments")
        XCTAssertFalse(attrString.hasTextAttachment)
    }
}
