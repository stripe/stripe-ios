//
//  STPPaymentMethodCryptoTests.swift
//  StripeiOSTests
//
//  Created by Eric Zhang on 11/20/24.
//

@testable import Stripe
import StripeCoreTestUtils
import XCTest

class STPPaymentMethodCryptoTests: XCTestCase {
    func testObjectDecoding() {
        let crypto = STPPaymentMethodCrypto.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("CryptoPaymentMethod") as? [AnyHashable: Any])
        XCTAssertNotNil(crypto, "Failed to decode JSON")
    }
}
