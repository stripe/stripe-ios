//
//  STPPaymentMethodBoletoTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 9/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
import StripeCoreTestUtils
@testable import Stripe

class STPPaymentMethodBoletoTests: XCTestCase {

    private(set) var boletoJSON: [AnyHashable: Any]?

    static let boletoPaymentIntentClientSecret = "pi_3JYFj9JQVROkWvqT0d2HYaTk_secret_c2PniS4q2A7XhZ9mbFwOTpN08"

    func _retrieveBoletoJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        if let boletoJSON = boletoJSON {
            completion(boletoJSON)
        } else {
            let client = STPAPIClient(publishableKey: STPTestingBRPublishableKey)
            client.retrievePaymentIntent(
                withClientSecret: Self.boletoPaymentIntentClientSecret,
                expand: ["payment_method"]
            ) { [self] paymentIntent, _ in
                boletoJSON = paymentIntent?.paymentMethod?.boleto?.allResponseFields
                completion(boletoJSON ?? [:])
            }
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveBoletoJSON({ json in
            let boleto = STPPaymentMethodBoleto.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(boleto, "Failed to decode JSON")
            XCTAssertEqual(boleto?.taxID, "00.000.000/0001-91", "It must properly decode `taxID`")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }

}
