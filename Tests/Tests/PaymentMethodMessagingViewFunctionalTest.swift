//
//  PaymentMethodMessagingViewFunctionalTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 9/28/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import Stripe
@_spi(STP) @testable import StripePaymentsUI

class PaymentMethodMessagingViewFunctionalTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreatesViewFromServerResponse() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let config = PaymentMethodMessagingView.Configuration(paymentMethods: [], currency: "USD", amount: 1099, apiClient: apiClient)
        let createViewExpectation = expectation(description: "")
        PaymentMethodMessagingView.create(configuration: config) { [weak self] result in
            switch result {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .success(let view):
                self?.validate(view)
            }
            createViewExpectation.fulfill()
        }
//        waitForExpectations(timeout: 10)
//        // ...making another request...
//        let createViewExpectation2 = expectation(description: "")
//        PaymentMethodMessagingView.create(configuration: config) { result in
//            switch result {
//            case .failure(let error):
//                XCTFail(error.localizedDescription)
//            case .success(let view):
//                print(view)
//            }
//            // ...should use the cache
//            createViewExpectation2.fulfill()
//        }
//        waitForExpectations(timeout: 10)
//
//        // ...changing the params
//        apiClient.publishableKey = "pk_1234"
//        config.currency = "FF"
//        let createViewExpectation3 = expectation(description: "")
//        PaymentMethodMessagingView.create(configuration: config) { result in
//            switch result {
//            case .failure(let error):
//                XCTFail(error.localizedDescription)
//            case .success(let view):
//                print(view)
//            }
//            // ...should not use the cache
//            createViewExpectation3.fulfill()
//        }
        waitForExpectations(timeout: 10)
    }
    
    func testInitializingWithBadConfigurationReturnsError() {
    }
    
    func testInitializingWithBadHTMLReturnsError() {
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let config = PaymentMethodMessagingView.Configuration(paymentMethods: [], currency: "USD", amount: 1099, apiClient: apiClient)
        let createViewExpectation = expectation(description: "")
        PaymentMethodMessagingView.create(configuration: config) { [weak self] result in
            switch result {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .success(let view):
                self?.validate(view)
            }
            createViewExpectation.fulfill()
        }
    }
    
    @available(iOS 13.0, *)
    func testReplacesImagesForDarkMode() {
        URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let config = PaymentMethodMessagingView.Configuration(paymentMethods: [], currency: "USD", amount: 1099, apiClient: apiClient)
        let createViewExpectation = expectation(description: "")
        PaymentMethodMessagingView.create(configuration: config) { [weak self] result in
            switch result {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .success(let view):
                let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 1026))
                window.isHidden = false
                // ...in dark mode...
                window.overrideUserInterfaceStyle = .dark
                window.addSubview(view)
                self?.validate(view)
            }
            createViewExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)

    }
    
    func validate(_ view: PaymentMethodMessagingView) {
        // We can't snapshot test the real view, since its appearance can change
        // Instead, we'll assert that it contains at least one image
        var atLeastOneImageExists = false
        view.textView.attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: view.textView.attributedText.length), options: []) { (value, range, stop) in
            if let textAttachment = value as? NSTextAttachment, textAttachment.fileType?.range(of: ".png") != nil {
                atLeastOneImageExists = true
            }
        }
        XCTAssert(atLeastOneImageExists)
    }
}
