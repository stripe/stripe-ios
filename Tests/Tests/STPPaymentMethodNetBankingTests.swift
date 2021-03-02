//
//  STPPaymentMethodNetBankingTests.swift
//  StripeiOS
//
//  Created by Anirudh Bhargava on 11/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPPaymentMethodNetBankingTests: XCTestCase {
    private(set) var netbankingJSON: [AnyHashable: Any]?

    func _retrieveNetBankingJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        if let netbankingJSON = netbankingJSON {
            completion(netbankingJSON)
        } else {
            let client = STPAPIClient(publishableKey: STPTestingINPublishableKey)
            client.retrievePaymentIntent(
                withClientSecret: "pi_1HoPqsBte6TMTRd4jX0PwrFa_secret_ThiIwyssre9qjJ6gtmghC21fk",
                expand: ["payment_method"]
            ) { [self] paymentIntent, _ in
                netbankingJSON = paymentIntent?.paymentMethod?.netBanking?.allResponseFields
                completion(netbankingJSON ?? [:])
            }
        }
    }

    func testCorrectParsing() {
        let jsonExpectation = XCTestExpectation(description: "Fetch NetBanking JSON")
        _retrieveNetBankingJSON({ json in
            let netbanking = STPPaymentMethodNetBanking.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(netbanking, "Failed to decode JSON")
            jsonExpectation.fulfill()
        })
        wait(for: [jsonExpectation], timeout: STPTestingNetworkRequestTimeout)
    }
}
