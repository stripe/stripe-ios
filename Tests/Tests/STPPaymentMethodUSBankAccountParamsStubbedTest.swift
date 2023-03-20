//
//  STPPaymentMethodUSBankAccountParamsStubbedTest.swift
//  StripeiOS Tests
//
//  Created by John Woo on 3/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@testable @_spi(STP) import Stripe
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeApplePay

import StripeCoreTestUtils
import OHHTTPStubs

class STPPaymentMethodUSBankAccountParamsStubbedTest: APIStubbedTestCase {
    func testus_bank_account_withoutNetworks() {
        let stubbedApiClient = stubbedAPIClient()
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/payment_methods") ?? false
        } response: { urlRequest in
            let jsonText = """
                 {
                   "id": "pm_1KgvOfFY0qyl6XeW7RfvDvxE",
                   "object": "payment_method",
                   "billing_details": {
                     "address": {
                       "city": null,
                       "country": null,
                       "line1": null,
                       "line2": null,
                       "postal_code": null,
                       "state": null
                     },
                     "email": "tester@example.com",
                     "name": "iOS CI Tester",
                     "phone": null
                   },
                   "created": 1648146513,
                   "customer": null,
                   "livemode": false,
                   "type": "us_bank_account",
                   "us_bank_account": {
                     "account_holder_type": "individual",
                     "account_type": "checking",
                     "bank_name": "STRIPE TEST BANK",
                     "fingerprint": "ickfX9sbxIyAlbuh",
                     "last4": "6789",
                     "linked_account": null,
                     "routing_number": "110000000"
                   }
                 }
                 """
            return HTTPStubsResponse(data: jsonText.data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        let usBankAccountParams = STPPaymentMethodUSBankAccountParams()
        usBankAccountParams.accountType = .checking
        usBankAccountParams.accountHolderType = .individual
        usBankAccountParams.accountNumber = "000123456789"
        usBankAccountParams.routingNumber = "110000000"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "iOS CI Tester"
        billingDetails.email = "tester@example.com"

        let params = STPPaymentMethodParams(usBankAccount: usBankAccountParams,
                                            billingDetails: billingDetails,
                                            metadata: nil)

        let exp = expectation(description: "Payment Method US Bank Account create")
        stubbedApiClient.createPaymentMethod(with: params) { (paymentMethod: STPPaymentMethod?, error: Error?) in
            XCTAssertNil(error);
            XCTAssertNotNil(paymentMethod, "Payment method should be populated");
            XCTAssertEqual(paymentMethod?.type, .USBankAccount, "Incorrect PaymentMethod type");
            XCTAssertNotNil(paymentMethod?.usBankAccount, "The `usBankAccount` property must be populated");
            XCTAssertEqual(paymentMethod?.usBankAccount?.accountHolderType, .individual, "`accountHolderType` should be individual")
            XCTAssertEqual(paymentMethod?.usBankAccount?.accountType, .checking, "`accountType` should be checking")
            XCTAssertEqual(paymentMethod?.usBankAccount?.last4, "6789", "`last4` should be 6789")
            XCTAssertNil(paymentMethod?.usBankAccount?.networks)
            exp.fulfill()

        }
        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }
    func testus_bank_account_networksInPayloadWithPreferred() {

        let stubbedApiClient = stubbedAPIClient()
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/payment_methods") ?? false
        } response: { urlRequest in
            let jsonText = """
                 {
                   "id": "pm_1KgvOfFY0qyl6XeW7RfvDvxE",
                   "object": "payment_method",
                   "billing_details": {
                     "address": {
                       "city": null,
                       "country": null,
                       "line1": null,
                       "line2": null,
                       "postal_code": null,
                       "state": null
                     },
                     "email": "tester@example.com",
                     "name": "iOS CI Tester",
                     "phone": null
                   },
                   "created": 1648146513,
                   "customer": null,
                   "livemode": false,
                   "type": "us_bank_account",
                   "us_bank_account": {
                     "account_holder_type": "individual",
                     "account_type": "checking",
                     "bank_name": "STRIPE TEST BANK",
                     "fingerprint": "ickfX9sbxIyAlbuh",
                     "last4": "6789",
                     "linked_account": null,
                     "networks": {
                       "preferred": "ach",
                       "supported": [
                         "ach"
                       ]
                     },
                     "routing_number": "110000000"
                   }
                 }
                 """
            return HTTPStubsResponse(data: jsonText.data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        let usBankAccountParams = STPPaymentMethodUSBankAccountParams()
        usBankAccountParams.accountType = .checking
        usBankAccountParams.accountHolderType = .individual
        usBankAccountParams.accountNumber = "000123456789"
        usBankAccountParams.routingNumber = "110000000"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "iOS CI Tester"
        billingDetails.email = "tester@example.com"

        let params = STPPaymentMethodParams(usBankAccount: usBankAccountParams,
                                            billingDetails: billingDetails,
                                            metadata: nil)

        let exp = expectation(description: "Payment Method US Bank Account create")


        stubbedApiClient.createPaymentMethod(with: params) { (paymentMethod: STPPaymentMethod?, error: Error?) in

            XCTAssertNil(error);
            XCTAssertNotNil(paymentMethod, "Payment method should be populated");
            XCTAssertEqual(paymentMethod?.type, .USBankAccount, "Incorrect PaymentMethod type");
            XCTAssertNotNil(paymentMethod?.usBankAccount, "The `usBankAccount` property must be populated");
            XCTAssertEqual(paymentMethod?.usBankAccount?.accountHolderType, .individual, "`accountHolderType` should be individual")
            XCTAssertEqual(paymentMethod?.usBankAccount?.accountType, .checking, "`accountType` should be checking")
            XCTAssertEqual(paymentMethod?.usBankAccount?.last4, "6789", "`last4` should be 6789")
            XCTAssertEqual(paymentMethod?.usBankAccount?.networks?.preferred, "ach")
            XCTAssertEqual(paymentMethod?.usBankAccount?.networks?.supported.count, 1)
            XCTAssertEqual(paymentMethod?.usBankAccount?.networks?.supported.first, "ach")
            exp.fulfill()

        }
        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }
    func testus_bank_account_networksInPayloadWithoutPreferred() {

        let stubbedApiClient = stubbedAPIClient()
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/payment_methods") ?? false
        } response: { urlRequest in
            let jsonText = """
                 {
                   "id": "pm_1KgvOfFY0qyl6XeW7RfvDvxE",
                   "object": "payment_method",
                   "billing_details": {
                     "address": {
                       "city": null,
                       "country": null,
                       "line1": null,
                       "line2": null,
                       "postal_code": null,
                       "state": null
                     },
                     "email": "tester@example.com",
                     "name": "iOS CI Tester",
                     "phone": null
                   },
                   "created": 1648146513,
                   "customer": null,
                   "livemode": false,
                   "type": "us_bank_account",
                   "us_bank_account": {
                     "account_holder_type": "individual",
                     "account_type": "checking",
                     "bank_name": "STRIPE TEST BANK",
                     "fingerprint": "ickfX9sbxIyAlbuh",
                     "last4": "6789",
                     "linked_account": null,
                     "networks": {
                       "supported": [
                         "ach"
                       ]
                     },
                     "routing_number": "110000000"
                   }
                 }
                 """
            return HTTPStubsResponse(data: jsonText.data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        let usBankAccountParams = STPPaymentMethodUSBankAccountParams()
        usBankAccountParams.accountType = .checking
        usBankAccountParams.accountHolderType = .individual
        usBankAccountParams.accountNumber = "000123456789"
        usBankAccountParams.routingNumber = "110000000"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "iOS CI Tester"
        billingDetails.email = "tester@example.com"

        let params = STPPaymentMethodParams(usBankAccount: usBankAccountParams,
                                            billingDetails: billingDetails,
                                            metadata: nil)

        let exp = expectation(description: "Payment Method US Bank Account create")


        stubbedApiClient.createPaymentMethod(with: params) { (paymentMethod: STPPaymentMethod?, error: Error?) in

            XCTAssertNil(error);
            XCTAssertNotNil(paymentMethod, "Payment method should be populated");
            XCTAssertEqual(paymentMethod?.type, .USBankAccount, "Incorrect PaymentMethod type");
            XCTAssertNotNil(paymentMethod?.usBankAccount, "The `usBankAccount` property must be populated");
            XCTAssertEqual(paymentMethod?.usBankAccount?.accountHolderType, .individual, "`accountHolderType` should be individual")
            XCTAssertEqual(paymentMethod?.usBankAccount?.accountType, .checking, "`accountType` should be checking")
            XCTAssertEqual(paymentMethod?.usBankAccount?.last4, "6789", "`last4` should be 6789")
            XCTAssertNil(paymentMethod?.usBankAccount?.networks?.preferred)
            XCTAssertEqual(paymentMethod?.usBankAccount?.networks?.supported.count, 1)
            XCTAssertEqual(paymentMethod?.usBankAccount?.networks?.supported.first, "ach")
            exp.fulfill()

        }
        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }
}
