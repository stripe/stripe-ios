//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPCustomerTest.m
//  Stripe
//
//  Created by Ben Guo on 7/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

class STPCustomerTest: XCTestCase {
    func testDecoding_invalidJSON() {
        let sut = STPCustomer.decodedObject(fromAPIResponse: [:])
        XCTAssertNil(sut)
    }

    func testDecoding_validJSON() {
        var card1 = STPTestUtils.jsonNamed("Card")
        card1!["id"] = "card_123"

        var card2 = STPTestUtils.jsonNamed("Card")
        card2!["id"] = "card_456"

        var applePayCard1 = STPTestUtils.jsonNamed("Card")
        applePayCard1!["id"] = "card_apple_pay1"
        applePayCard1!["tokenization_method"] = "apple_pay"

        var applePayCard2 = applePayCard1
        applePayCard2!["id"] = "card_apple_pay2"

        let cardSource = STPTestUtils.jsonNamed("CardSource")
        let threeDSSource = STPTestUtils.jsonNamed("3DSSource")

        var customer = STPTestUtils.jsonNamed("Customer")
        var sources = customer!["sources"] as? [AnyHashable: Any]
        sources?["data"] = [applePayCard1, card1, applePayCard2, card2, cardSource, threeDSSource]
        customer!["default_source"] = card1!["id"]
        if let sources {
            customer!["sources"] = sources
        }

        guard let sut = STPCustomer.decodedObject(fromAPIResponse: customer) else {
            XCTFail()
            return
        }
        XCTAssertEqual(sut.stripeID, customer!["id"] as! String)
        XCTAssertTrue(sut.sources.count == 4)
        XCTAssertEqual(sut.sources[0].stripeID, card1!["id"] as! String)
        XCTAssertEqual(sut.sources[1].stripeID, card2!["id"] as! String)
        XCTAssertEqual(sut.defaultSource!.stripeID, card1!["id"] as! String)
        XCTAssertEqual(sut.sources[2].stripeID, cardSource!["id"] as! String)
        XCTAssertEqual(sut.sources[3].stripeID, threeDSSource!["id"] as! String)

        XCTAssertEqual(sut.shippingAddress!.name, (customer!["shipping"] as! [AnyHashable: Any])["name"] as? String)
        XCTAssertEqual(sut.shippingAddress!.phone, (customer!["shipping"] as! [AnyHashable: Any])["phone"] as? String)
        let addressDict = (customer!["shipping"] as! [AnyHashable: Any])["address"] as! [AnyHashable: String]
        XCTAssertEqual(sut.shippingAddress!.city, addressDict["city"])
        XCTAssertEqual(sut.shippingAddress!.country, addressDict["country"])
        XCTAssertEqual(sut.shippingAddress!.line1, addressDict["line1"])
        XCTAssertEqual(sut.shippingAddress!.line2, addressDict["line2"])
        XCTAssertEqual(sut.shippingAddress!.postalCode, addressDict["postal_code"])
        XCTAssertEqual(sut.shippingAddress!.state, addressDict["state"])
    }
}
