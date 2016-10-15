//
//  AddCardLocalizationTests.swift
//  Stripe iOS Example (Simple)
//
//  Created by Brian Dorfman on 10/14/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import FBSnapshotTestCase
import Stripe

class TestAPIClient: NSObject, STPBackendAPIAdapter {
    static let sharedClient = TestAPIClient()
    @objc func retrieveCustomer(_ completion: @escaping STPCustomerCompletionBlock) {
        completion(nil, nil)
    }
    
    @objc func selectDefaultCustomerSource(_ source: STPSource, completion: @escaping STPErrorBlock) {
        completion(nil)
    }
    
    @objc func attachSource(toCustomer source: STPSource, completion: @escaping STPErrorBlock) {
        completion(nil)
    }
}

class AddCardLocalizationTests: FBSnapshotTestCase {
    
    var paymentConfig: STPPaymentConfiguration!
    
    override func setUp() {
        super.setUp()
        
        self.recordMode = true
        
        let config = STPPaymentConfiguration.init()
        config.publishableKey = "test"
        config.companyName = "Test Company"
        config.requiredBillingAddressFields = .full
        config.additionalPaymentMethods = .all
        config.smsAutofillDisabled = false
        
        self.paymentConfig = config
        
    }
    
    func performSnapshotTestFor(language: String) {
        STPLocalizationUtils.overrideLanguage(to: language)
        
        let addCardVC = STPAddCardViewController.init(configuration: self.paymentConfig, 
                                                  theme: STPTheme.default())
        
        let navController = UINavigationController.init(rootViewController: addCardVC)
        navController.view.frame = CGRect(x: 0, y: 0, width: 320, height: 750)
        
        // TODO: dig into the controller's scroll view to dig out the actual height needed

        FBSnapshotVerifyView(navController.view)
        
        STPLocalizationUtils.overrideLanguage(to: nil)
    }
    
    func testGerman() {
        performSnapshotTestFor(language: "de")
    }
    
    func testEnglish() {
        performSnapshotTestFor(language: "en")
    }
    
    func testSpanish() {
        performSnapshotTestFor(language: "es")
    }    
    
    func testFrench() {
        performSnapshotTestFor(language: "fr")
    }
    
    func testItalian() {
        performSnapshotTestFor(language: "it")
    }
    
    func testJapanese() {
        performSnapshotTestFor(language: "ja")
    }
    
    func testDutch() {
        performSnapshotTestFor(language: "nl")
    }
    
    func testChinese() {
        performSnapshotTestFor(language: "zh-Hans")
    }
}
