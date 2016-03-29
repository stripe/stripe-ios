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
        UIApplication.sharedApplication().keyWindow!.rootViewController = vc
        XCTAssertNotNil(vc.view)
        vc.presentViewController(sut, animated: true, completion: nil)
        XCTAssertNotNil(sut.view)
    }
    
    override func tearDown() {
        super.tearDown()
        self.paymentRequest = nil
        self.mockAPIClient = nil
        self.sut = nil
    }

    func testFirstVCIsEmailVC() {
        let vc = self.sut!.navigationController!.topViewController
        XCTAssertTrue(vc is STPEmailEntryViewController)
    }

    func testCancelingEmailEntryTellsDelegate() {
        let nc = self.sut!.navigationController!
        let vc = nc.topViewController as! STPEmailEntryViewController
        let exp = self.expectationWithDescription("cancel")
        let delegate = MockSTPPaymentAuthVCDelegate()
        sut?.delegate = delegate
        delegate.onDidCancel = {
            exp.fulfill()
        }
        XCTAssertNotNil(vc.view)
        let cancelButton = vc.navigationItem.leftBarButtonItem!
        cancelButton.target!.performSelector(cancelButton.action, withObject: cancelButton)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

}
