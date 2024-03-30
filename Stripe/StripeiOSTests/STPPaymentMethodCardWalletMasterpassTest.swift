//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodCardWalletMasterpassTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPPaymentMethodCardWalletMasterpassTest: XCTestCase {
    func testDecodedObjectFromAPIResponseMapping() {
        // We reuse the visa checkout JSON because it's identical to the masterpass version
        let response = ((STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)["card"] as! [AnyHashable: Any])["wallet"] as! [AnyHashable: Any])["visa_checkout"] as? [AnyHashable: Any]
        let masterpass = STPPaymentMethodCardWalletMasterpass.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(masterpass)
        XCTAssertEqual(masterpass?.name, "Jenny")
        XCTAssertEqual(masterpass?.email, "jenny@example.com")
        XCTAssertNotNil(masterpass?.billingAddress)
        XCTAssertNotNil(masterpass?.shippingAddress)
    }
}
