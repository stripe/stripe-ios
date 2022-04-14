//
//  STPCardFormViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

class STPCardFormViewSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testEmpty() {
        let formView = STPCardFormView(billingAddressCollection: .automatic)
        formView.countryCode = "US"
        formView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))

        STPSnapshotVerifyView(formView)
    }

    func testIncomplete() {
        let formView = STPCardFormView(billingAddressCollection: .automatic)
        formView.countryCode = "US"
        formView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 265))

        formView.numberField.text = "4242"
        formView.numberField.textDidChange()
        formView.cvcField.text = "123"
        formView.cvcField.textDidChange()

        STPSnapshotVerifyView(formView)
    }

    // valid expiration date will change over time so we just test without it
    func testCompleteWithoutExpiry() {
        let formView = STPCardFormView(billingAddressCollection: .automatic)
        formView.countryCode = "US"
        formView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))

        formView.numberField.text = "4242424242424242"
        formView.numberField.textDidChange()
        formView.cvcField.text = "123"
        formView.cvcField.textDidChange()
        formView.postalCodeField.text = "12345"

        STPSnapshotVerifyView(formView)
    }

    func testEmptyHiddenPostalCode() {
        let formView = STPCardFormView(billingAddressCollection: .automatic)
        formView.countryCode = "AE"
        formView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))

        STPSnapshotVerifyView(formView)
    }

    func testWithFullBillingDetails() {
        let formView = STPCardFormView(billingAddressCollection: .required)
        formView.countryCode = "US"
        formView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 400))

        STPSnapshotVerifyView(formView)
    }
    
    // MARK: - Standalone
    
    func testDefaultStandalone() {
        let formView = STPCardFormView()
        formView.countryCode = "US"
        formView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))
        
        STPSnapshotVerifyView(formView)
    }
    
    func testBorderlessStandalone() {
        let formView = STPCardFormView(style: .borderless)
        formView.countryCode = "US"
        formView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))
        
        STPSnapshotVerifyView(formView)
    }
    
    func testCustomBackgroundStandalone() {
        let formView = STPCardFormView()
        formView.countryCode = "US"
        formView.backgroundColor = .green
        formView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))
        
        STPSnapshotVerifyView(formView)
    }
    
    func testCustomBackgroundDisabledColorStandalone() {
        let formView = STPCardFormView()
        formView.countryCode = "US"
        formView.disabledBackgroundColor = .green
        formView.isUserInteractionEnabled = false
        formView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))
        
        STPSnapshotVerifyView(formView)
    }
    
    func testBorderlessStandaloneIncomplete() {
        let formView = STPCardFormView(style: .borderless)
        formView.countryCode = "US"
        formView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))

        formView.numberField.text = "4242"
        formView.numberField.textDidChange()
        formView.cvcField.text = "123"
        formView.cvcField.textDidChange()

        STPSnapshotVerifyView(formView)
    }

}
