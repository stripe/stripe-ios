//
//  STPPaymentMethodUSBankAccountParamsTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
import StripeCoreTestUtils
@_spi(STP) import StripeCore
@testable import Stripe

class STPPaymentMethodUSBankAccountParamsTest: XCTestCase {
    
    let apiClient: STPAPIClient = {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        return client
    }()

    func testCreateUSBankAccountPaymentMethod_checking_individual() {
        let usBankAccountParams = STPPaymentMethodUSBankAccountParams()
        usBankAccountParams.accountType = .checking
        XCTAssertEqual(usBankAccountParams.accountTypeString, "checking")
        usBankAccountParams.accountHolderType = .individual
        XCTAssertEqual(usBankAccountParams.accountHolderTypeString, "individual")
        usBankAccountParams.accountNumber = "000123456789"
        usBankAccountParams.routingNumber = "110000000"
        
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "iOS CI Tester"
        billingDetails.email = "tester@example.com"
        
        let params = STPPaymentMethodParams(usBankAccount: usBankAccountParams,
                                            billingDetails: billingDetails,
                                            metadata: nil)
        
        let exp = expectation(description: "Payment Method US Bank Account create")

        
        apiClient.createPaymentMethod(with: params) { (paymentMethod: STPPaymentMethod?, error: Error?) in

            XCTAssertNil(error);
            XCTAssertNotNil(paymentMethod, "Payment method should be populated");
            XCTAssertEqual(paymentMethod?.type, .USBankAccount, "Incorrect PaymentMethod type");
            XCTAssertNotNil(paymentMethod?.usBankAccount, "The `usBankAccount` property must be populated");
            XCTAssertEqual(paymentMethod?.usBankAccount?.accountHolderType, .individual, "`accountHolderType` should be individual")
            XCTAssertEqual(paymentMethod?.usBankAccount?.accountType, .checking, "`accountType` should be checking")
            XCTAssertEqual(paymentMethod?.usBankAccount?.last4, "6789", "`last4` should be 6789")
            
            exp.fulfill()

        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }
    
    func testCreateUSBankAccountPaymentMethod_savings_company() {
        let usBankAccountParams = STPPaymentMethodUSBankAccountParams()
        usBankAccountParams.accountType = .savings
        XCTAssertEqual(usBankAccountParams.accountTypeString, "savings")
        usBankAccountParams.accountHolderType = .company
        XCTAssertEqual(usBankAccountParams.accountHolderTypeString, "company")
        usBankAccountParams.accountNumber = "000123456789"
        usBankAccountParams.routingNumber = "110000000"
        
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "iOS CI Tester"
        billingDetails.email = "tester@example.com"
        
        let params = STPPaymentMethodParams(usBankAccount: usBankAccountParams,
                                            billingDetails: billingDetails,
                                            metadata: nil)
        
        let exp = expectation(description: "Payment Method US Bank Account create")

        
        apiClient.createPaymentMethod(with: params) { (paymentMethod: STPPaymentMethod?, error: Error?) in

            XCTAssertNil(error);
            XCTAssertNotNil(paymentMethod, "Payment method should be populated");
            XCTAssertEqual(paymentMethod?.type, .USBankAccount, "Incorrect PaymentMethod type");
            XCTAssertNotNil(paymentMethod?.usBankAccount, "The `usBankAccount` property must be populated");
            XCTAssertEqual(paymentMethod?.usBankAccount?.accountHolderType, .company, "`accountHolderType` should be company")
            XCTAssertEqual(paymentMethod?.usBankAccount?.accountType, .savings, "`accountType` should be savings")
            XCTAssertEqual(paymentMethod?.usBankAccount?.last4, "6789", "`last4` should be 6789")
            
            exp.fulfill()
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }
    
    func testCreateUSBankAccountPaymentMethod_checking_individual_set_with_string() {
        let usBankAccountParams = STPPaymentMethodUSBankAccountParams()
        usBankAccountParams.accountTypeString = "checking"
        XCTAssertEqual(usBankAccountParams.accountType, .checking)
        usBankAccountParams.accountHolderTypeString = "individual"
        XCTAssertEqual(usBankAccountParams.accountHolderType, .individual)
        usBankAccountParams.accountNumber = "000123456789"
        usBankAccountParams.routingNumber = "110000000"
        
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "iOS CI Tester"
        billingDetails.email = "tester@example.com"
        
        let params = STPPaymentMethodParams(usBankAccount: usBankAccountParams,
                                            billingDetails: billingDetails,
                                            metadata: nil)
        
        let exp = expectation(description: "Payment Method US Bank Account create")

        
        apiClient.createPaymentMethod(with: params) { (paymentMethod: STPPaymentMethod?, error: Error?) in

            XCTAssertNil(error);
            XCTAssertNotNil(paymentMethod, "Payment method should be populated");
            XCTAssertEqual(paymentMethod?.type, .USBankAccount, "Incorrect PaymentMethod type");
            XCTAssertNotNil(paymentMethod?.usBankAccount, "The `usBankAccount` property must be populated");
            XCTAssertEqual(paymentMethod?.usBankAccount?.accountHolderType, .individual, "`accountHolderType` should be individual")
            XCTAssertEqual(paymentMethod?.usBankAccount?.accountType, .checking, "`accountType` should be checking")
            XCTAssertEqual(paymentMethod?.usBankAccount?.last4, "6789", "`last4` should be 6789")
            
            exp.fulfill()
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }
    
    func testCreateUSBankAccountPaymentMethod_savings_company_set_with_string() {
        let usBankAccountParams = STPPaymentMethodUSBankAccountParams()
        usBankAccountParams.accountTypeString = "savings"
        XCTAssertEqual(usBankAccountParams.accountType, .savings)
        usBankAccountParams.accountHolderTypeString = "company"
        XCTAssertEqual(usBankAccountParams.accountHolderType, .company)
        usBankAccountParams.accountNumber = "000123456789"
        usBankAccountParams.routingNumber = "110000000"
        
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "iOS CI Tester"
        billingDetails.email = "tester@example.com"
        
        let params = STPPaymentMethodParams(usBankAccount: usBankAccountParams,
                                            billingDetails: billingDetails,
                                            metadata: nil)
        
        let exp = expectation(description: "Payment Method US Bank Account create")

        
        apiClient.createPaymentMethod(with: params) { (paymentMethod: STPPaymentMethod?, error: Error?) in

            XCTAssertNil(error);
            XCTAssertNotNil(paymentMethod, "Payment method should be populated");
            XCTAssertEqual(paymentMethod?.type, .USBankAccount, "Incorrect PaymentMethod type");
            XCTAssertNotNil(paymentMethod?.usBankAccount, "The `usBankAccount` property must be populated");
            XCTAssertEqual(paymentMethod?.usBankAccount?.accountHolderType, .company, "`accountHolderType` should be company")
            XCTAssertEqual(paymentMethod?.usBankAccount?.accountType, .savings, "`accountType` should be savings")
            XCTAssertEqual(paymentMethod?.usBankAccount?.last4, "6789", "`last4` should be 6789")
            
            exp.fulfill()
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
