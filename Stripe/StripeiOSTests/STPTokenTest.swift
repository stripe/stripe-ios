//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPTokenTest.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/9/12.
//
//

import Stripe
import XCTest

class STPTokenTest: XCTestCase {
    func buildTokenResponse() -> [AnyHashable: Any]? {
        let cardDict = [
            "id": "card_123",
            "exp_month": "12",
            "exp_year": "2013",
            "name": "Smerlock Smolmes",
            "address_line1": "221A Baker Street",
            "address_city": "New York",
            "address_state": "NY",
            "address_zip": "12345",
            "address_country": "US",
            "last4": "1234",
            "brand": "Visa",
            "fingerprint": "Fingolfin",
            "country": "JP",
        ]

        let tokenDict = [
            "id": "id_for_token",
            "object": "token",
            "livemode": NSNumber(value: false),
            "created": NSNumber(value: 1353025450.0),
            "used": NSNumber(value: false),
            "card": cardDict,
            "type": "card",
        ] as [String: Any]
        return tokenDict
    }

    func testCreatingTokenWithAttributeDictionarySetsAttributes() {
        guard
            let token = STPToken.decodedObject(fromAPIResponse: buildTokenResponse()),
            let timeInterval = token.created?.timeIntervalSince1970
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(token.tokenId, "id_for_token")
        XCTAssertEqual(token.livemode, false, "Generated token has the correct livemode")
        XCTAssertEqual(token.type, STPTokenType.card, "Generated token has incorrect type")

        XCTAssertEqual(timeInterval, 1353025450.0, accuracy: 1.0, "Generated token has the correct created time")
    }

    func testCreatingTokenSetsAdditionalResponseFields() {
        var tokenResponse = buildTokenResponse()
        tokenResponse?["foo"] = "bar"
        let token = STPToken.decodedObject(fromAPIResponse: tokenResponse)
        let allResponseFields = token?.allResponseFields
        XCTAssertEqual(allResponseFields?["foo"] as? String, "bar")
        XCTAssertEqual(allResponseFields?["livemode"] as? NSNumber, NSNumber(value: false))
        XCTAssertNil(allResponseFields?["baz"])
    }
}
