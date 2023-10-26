//
//  PaymentSheetLoaderMockedTest.swift
//  StripePaymentSheetTests
//

@testable import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

class PaymentSheetLoaderStubbedTest: APIStubbedTestCase {
    private func configuration(apiClient: STPAPIClient) -> PaymentSheet.Configuration {
        var config = PaymentSheet.Configuration()
        config.apiClient = apiClient

        let customer = PaymentSheet.CustomerConfiguration(id: "123", ephemeralKeySecret: "ek_456")
        config.customer = customer
        config.allowsDelayedPaymentMethods = true
        return config
    }

    func testReturningCustomerWithNoSavedCards() throws {
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")
        StubbedBackend.stubSessions(paymentMethods: "\"card\", \"us_bank_account\"")

        let loaded = expectation(description: "Loaded")
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: self.configuration(apiClient: stubbedAPIClient())
        ) { result in
            switch result {
            case .success(let intent, let paymentMethods, _):
                guard case .paymentIntent(let paymentIntent) = intent else {
                    XCTFail("Expecting payment intent")
                    return
                }
                XCTAssertEqual(paymentIntent.stripeId, "pi_3Kth")
                XCTAssertEqual(paymentMethods.count, 0)
                loaded.fulfill()
            case .failure:
                XCTFail("Failed")
            }
        }
        wait(for: [loaded], timeout: 2)
    }

    func testReturningCustomerWithSingleSavedCard() throws {
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")
        StubbedBackend.stubSessions(paymentMethods: "\"card\", \"us_bank_account\"")

        let loaded = expectation(description: "Loaded")
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: self.configuration(apiClient: stubbedAPIClient())
        ) { result in
            switch result {
            case .success(let intent, let paymentMethods, _):
                guard case .paymentIntent(let paymentIntent) = intent else {
                    XCTFail("Expecting payment intent")
                    return
                }
                XCTAssertEqual(paymentIntent.stripeId, "pi_3Kth")
                XCTAssertEqual(paymentMethods.count, 1)
                XCTAssertEqual(paymentMethods[0].type, .card)
                loaded.fulfill()
            case .failure:
                XCTFail("Failed")
            }
        }
        wait(for: [loaded], timeout: 2)
    }

    func testReturningCustomerWithCardAndUSBankAccount_onlyCards() throws {
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withUSBank_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")
        StubbedBackend.stubSessions(paymentMethods: "\"card\"")

        let loaded = expectation(description: "Loaded")
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: self.configuration(apiClient: stubbedAPIClient())
        ) { result in
            switch result {
            case .success(let intent, let paymentMethods, _):
                guard case .paymentIntent(let paymentIntent) = intent else {
                    XCTFail("Expecting payment intent")
                    return
                }
                XCTAssertEqual(paymentIntent.stripeId, "pi_3Kth")
                XCTAssertEqual(paymentMethods.count, 1)
                XCTAssertEqual(paymentMethods[0].type, .card)
                loaded.fulfill()
            case .failure:
                XCTFail("Failed")
            }
        }
        wait(for: [loaded], timeout: 2)
    }

    func testReturningCustomerWithCardAndUSBankAccount() throws {
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withUSBank_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")
        StubbedBackend.stubSessions(paymentMethods: "\"card\", \"us_bank_account\"")

        let loaded = expectation(description: "Loaded")
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: self.configuration(apiClient: stubbedAPIClient())
        ) { result in
            switch result {
            case .success(let intent, let paymentMethods, _):
                guard case .paymentIntent(let paymentIntent) = intent else {
                    XCTFail("Expecting payment intent")
                    return
                }
                XCTAssertEqual(paymentIntent.stripeId, "pi_3Kth")
                XCTAssertEqual(paymentMethods.count, 2)
                XCTAssertEqual(paymentMethods[0].type, .card)
                XCTAssertEqual(paymentMethods[1].type, .USBankAccount)

                loaded.fulfill()
            case .failure:
                XCTFail("Failed")
            }
        }
        wait(for: [loaded], timeout: 2)
    }
}
