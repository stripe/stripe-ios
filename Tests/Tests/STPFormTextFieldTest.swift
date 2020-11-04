//
//  STPFormTextFieldTest.swift
//  Stripe
//
//  Created by Ben Guo on 3/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPFormTextFieldTest: XCTestCase {
  func testAutoFormattingBehavior_None() {
    let sut = STPFormTextField()
    sut.autoFormattingBehavior = .none
    sut.text = "123456789"
    XCTAssertEqual(sut.text, "123456789")
  }

  func testAutoFormattingBehavior_PhoneNumbers() {
    let sut = STPFormTextField()
    sut.autoFormattingBehavior = .phoneNumbers
    sut.text = "123456789"
    XCTAssertEqual(sut.text, "(123) 456-789")
  }

  func testAutoFormattingBehavior_CardNumbers() {
    let sut = STPFormTextField()
    sut.autoFormattingBehavior = .cardNumbers
    sut.text = "4242424242424242"
    XCTAssertEqual(sut.text, "4242424242424242")
    var range = NSRange()
    var value = sut.attributedText!.attribute(.kern, at: 0, effectiveRange: &range) as! Int
    XCTAssertEqual(value, 0)
    XCTAssertEqual(range.length, Int(3))
    value = sut.attributedText!.attribute(.kern, at: 3, effectiveRange: &range) as! Int
    XCTAssertEqual(value, 5)
    XCTAssertEqual(range.length, Int(1))
    value = sut.attributedText!.attribute(.kern, at: 4, effectiveRange: &range) as! Int
    XCTAssertEqual(value, 0)
    XCTAssertEqual(range.length, Int(3))
    value = sut.attributedText!.attribute(.kern, at: 7, effectiveRange: &range) as! Int
    XCTAssertEqual(value, 5)
    XCTAssertEqual(range.length, Int(1))
    value = sut.attributedText!.attribute(.kern, at: 8, effectiveRange: &range) as! Int
    XCTAssertEqual(value, 0)
    XCTAssertEqual(range.length, Int(3))
    value = sut.attributedText?.attribute(.kern, at: 11, effectiveRange: &range) as! Int
    XCTAssertEqual(value, 5)
    XCTAssertEqual(range.length, Int(1))
    value = sut.attributedText?.attribute(.kern, at: 12, effectiveRange: &range) as! Int
    XCTAssertEqual(value, 0)
    XCTAssertEqual(range.length, Int(4))
    XCTAssertEqual(sut.attributedText!.length, Int(16))

    sut.placeholder = "enteracardnumber"
    XCTAssertNil(sut.attributedPlaceholder!.attribute(.kern, at: 3, effectiveRange: &range))
  }
}
