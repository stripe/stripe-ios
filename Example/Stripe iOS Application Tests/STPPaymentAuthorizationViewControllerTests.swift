//
//  STPPaymentAuthorizationViewControllerTests.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/28/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import XCTest
import Stripe

class STPPaymentAuthorizationViewControllerTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testFirstPresentsEmailVC() {
        let paymentRequest = STPPaymentRequest(appleMerchantId: "woo")
        let sut = STPPaymentAuthorizationViewController(paymentRequest: paymentRequest, apiClient: STPAPIClient.sharedClient())
    }

}
