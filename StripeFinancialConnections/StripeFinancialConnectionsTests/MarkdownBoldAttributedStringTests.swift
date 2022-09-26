//
//  MarkdownBoldAttributedStringTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Krisjanis Gaidis on 9/22/22.
//

import XCTest
@testable import StripeFinancialConnections

class MarkdownBoldAttributedStringTests: XCTestCase {

    func testEmptyString() {
        let attributedString = NSMutableAttributedString(string: "")
        attributedString.addBoldFontAttributesByMarkdownRules(boldFont: .stripeFont(forTextStyle: .captionTightEmphasized))
        XCTAssert(attributedString == NSMutableAttributedString(string: ""))
    }
    
    func testSingleAsterisk() {
        let attributedString = NSMutableAttributedString(string: "*")
        attributedString.addBoldFontAttributesByMarkdownRules(boldFont: .stripeFont(forTextStyle: .captionTightEmphasized))
        XCTAssert(attributedString == NSMutableAttributedString(string: "*"))
    }
    
    func testDoubleAsterisk() {
        let attributedString = NSMutableAttributedString(string: "**")
        attributedString.addBoldFontAttributesByMarkdownRules(boldFont: .stripeFont(forTextStyle: .captionTightEmphasized))
        XCTAssert(attributedString == NSMutableAttributedString(string: ""))
    }
    
    func testNoAsterisks() {
        let attributedString = NSMutableAttributedString(string: "bold string")
        attributedString.addBoldFontAttributesByMarkdownRules(boldFont: .stripeFont(forTextStyle: .captionTightEmphasized))
        XCTAssert(attributedString == NSMutableAttributedString(string: "bold string"))
    }
    
    func testOneBold() {
        let boldFont = UIFont.stripeFont(forTextStyle: .captionTightEmphasized)
        let attributedString = NSMutableAttributedString(string: "*One Bold*")
        attributedString.addBoldFontAttributesByMarkdownRules(boldFont: boldFont)
        XCTAssert(attributedString == {
            let expectedAttributedString = NSMutableAttributedString(string: "One Bold")
            expectedAttributedString.addAttributes([.font: boldFont], range: NSMakeRange(0, 8))
            return expectedAttributedString
        }())
    }
    
    // this is a double-check that tests aren't just returning "true" all the time
    func testOneBoldNotEquals() {
        let boldFont = UIFont.stripeFont(forTextStyle: .captionTightEmphasized)
        let attributedString = NSMutableAttributedString(string: "*One Bold*")
        attributedString.addBoldFontAttributesByMarkdownRules(boldFont: boldFont)
        XCTAssert(attributedString != NSMutableAttributedString(string: "One Bold"))
    }
    
    func testOneBoldComplex() {
        let boldFont = UIFont.stripeFont(forTextStyle: .captionTightEmphasized)
        let attributedString = NSMutableAttributedString(string: "*One - $1.00 Bold*")
        attributedString.addBoldFontAttributesByMarkdownRules(boldFont: boldFont)
        XCTAssert(attributedString == {
            let expectedAttributedString = NSMutableAttributedString(string: "One - $1.00 Bold")
            expectedAttributedString.addAttributes([.font: boldFont], range: NSMakeRange(0, 16))
            return expectedAttributedString
        }())
    }
    
    func testOneBoldComplexVersionTwo() {
        let boldFont = UIFont.stripeFont(forTextStyle: .captionTightEmphasized)
        let attributedString = NSMutableAttributedString(string: "*One Bold* - $1.00")
        attributedString.addBoldFontAttributesByMarkdownRules(boldFont: boldFont)
        XCTAssert(attributedString == {
            let expectedAttributedString = NSMutableAttributedString(string: "One Bold - $1.00")
            expectedAttributedString.addAttributes([.font: boldFont], range: NSMakeRange(0, 8))
            return expectedAttributedString
        }())
    }
    
    func testOneBoldWithURL() {
        let boldFont = UIFont.stripeFont(forTextStyle: .captionTightEmphasized)
        let attributedString = NSMutableAttributedString(string: "[*One Bold*](https://www.stripe.com)")
        attributedString.addBoldFontAttributesByMarkdownRules(boldFont: boldFont)
        XCTAssert(attributedString == {
            let expectedAttributedString = NSMutableAttributedString(string: "[One Bold](https://www.stripe.com)")
            expectedAttributedString.addAttributes([.font: boldFont], range: NSMakeRange(1, 8))
            return expectedAttributedString
        }())
    }
    
    func testOneBoldWithExistingAttributes() {
        let boldFont = UIFont.stripeFont(forTextStyle: .captionTightEmphasized)
        let url = URL(string: "https://www.stripe.com")!
        
        let attributedString = NSMutableAttributedString(string: "word *One Bold* word")
        attributedString.addAttributes([.link: url], range: NSRange(location: 5, length: 10))
        attributedString.addBoldFontAttributesByMarkdownRules(boldFont: boldFont)
        
        XCTAssert(attributedString == {
            let expectedAttributedString = NSMutableAttributedString(string: "word One Bold word")
            expectedAttributedString.addAttributes([.link: url], range: NSMakeRange(5, 8))
            expectedAttributedString.addAttributes([.font: boldFont], range: NSMakeRange(5, 8))
            return expectedAttributedString
        }())
    }
    
    func testTwoBold() {
        let boldFont = UIFont.stripeFont(forTextStyle: .captionTightEmphasized)
        let attributedString = NSMutableAttributedString(string: "word *One Bold* word *Two Bold* word")
        attributedString.addBoldFontAttributesByMarkdownRules(boldFont: boldFont)
        XCTAssert(attributedString == {
            let expectedAttributedString = NSMutableAttributedString(string: "word One Bold word Two Bold word")
            expectedAttributedString.addAttributes([.font: boldFont], range: NSMakeRange(5, 8))
            expectedAttributedString.addAttributes([.font: boldFont], range: NSMakeRange(19, 8))
            return expectedAttributedString
        }())
    }
}
