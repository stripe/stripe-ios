//
//  STPPaymentAuthorizationViewControllerTests.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/28/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import XCTest
@testable import Stripe

class STPPaymentAuthorizationViewControllerTests: XCTestCase {

    let merchantID = "apple_merchant_id"
    let publishableKey = "publishable_key"
    var paymentRequest: STPPaymentRequest?
    var mockAPIClient: STPAPIClient?
    var sut: STPPaymentAuthorizationViewController?

    override func setUp() {
        super.setUp()
        let paymentRequest = STPPaymentRequest(appleMerchantId: self.merchantID)
        self.paymentRequest = paymentRequest
        let apiClient = MockSTPAPIClient(publishableKey: self.publishableKey)
        self.mockAPIClient = apiClient
        let sut = STPPaymentAuthorizationViewController(paymentRequest: paymentRequest,
                                                         apiClient: apiClient)
        self.sut = sut
        let vc = UIViewController()
        let window = UIWindow()
        window.rootViewController = vc
        vc.presentViewController(sut, animated: false, completion: nil)
    }
    
    override func tearDown() {
        super.tearDown()
        self.paymentRequest = nil
        self.mockAPIClient = nil
        self.sut = nil
    }

    func testFirstVCIsEmailVC() {
        let topVC = self.sut!.navigationController!.topViewController as! STPEmailEntryViewController

//        XCTAssertTrue(topVC is STPEmailEntryViewController)
    }

}
