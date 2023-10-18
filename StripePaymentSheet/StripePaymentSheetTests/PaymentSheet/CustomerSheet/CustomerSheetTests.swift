//
//  CustomerSheetTests.swift
//  StripePaymentSheetTests
//

import Foundation

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments
@testable import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

class CustomerSheetTests: APIStubbedTestCase {

    func testLoadPaymentMethodInfo_newCustomer() throws {
        let stubbedAPIClient = stubbedAPIClient()
        StubbedBackend.stubSessions(fileMock: .elementsSessionsLegacyCustomer_di_withNoSavedPM_200,
                                    paymentMethods: "\"card\"",
                                    requestCallback: { request in
            guard let requestUrl = request.url else {
                return false
            }
            return requestUrl.absoluteString.contains("legacy_customer_ephemeral_key")
        })
        StubbedBackend.stubSessions(fileMock: .elementsSessionsPaymentMethod_200,
                                    paymentMethods: "\"card\"",
                                    requestCallback: { request in
            guard let requestUrl = request.url else {
                return false
            }
            return !requestUrl.absoluteString.contains("legacy_customer_ephemeral_key")
        })

        let configuration = CustomerSheet.Configuration()
        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: "cus_123", ephemeralKeySecret: "ek_456")
        }, setupIntentClientSecretProvider: {
            return "si_789"
        }, apiClient: stubbedAPIClient)

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)
        customerSheet.loadPaymentMethodInfo { result in
            guard case .success((let paymentMethods, let selectedPaymentMethod, _)) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(paymentMethods.count, 0)
            XCTAssert(selectedPaymentMethod == nil)
            loadPaymentMethodInfo.fulfill()
        }
        wait(for: [loadPaymentMethodInfo], timeout: 5.0)
    }

    func testLoadPaymentMethodInfo_singleCard() throws {
        let stubbedAPIClient = stubbedAPIClient()
        StubbedBackend.stubSessions(fileMock: .elementsSessionsLegacyCustomer_di_withSavedCard_200,
                                    paymentMethods: "\"card\"",
                                    requestCallback: { request in
            guard let requestUrl = request.url else {
                return false
            }
            return requestUrl.absoluteString.contains("legacy_customer_ephemeral_key")
        })
        StubbedBackend.stubSessions(fileMock: .elementsSessionsPaymentMethod_200,
                                    paymentMethods: "\"card\"",
                                    requestCallback: { request in
            guard let requestUrl = request.url else {
                return false
            }
            return !requestUrl.absoluteString.contains("legacy_customer_ephemeral_key")
        })

        let configuration = CustomerSheet.Configuration()
        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: "cus_123", ephemeralKeySecret: "ek_456")
        }, setupIntentClientSecretProvider: {
            return "si_789"
        }, apiClient: stubbedAPIClient)

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)
        customerSheet.loadPaymentMethodInfo { result in
            guard case .success((let paymentMethods, let selectedPaymentMethod, _)) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(paymentMethods.count, 1)
            XCTAssertEqual(paymentMethods[0].type, .card)
            XCTAssert(selectedPaymentMethod == nil)
            loadPaymentMethodInfo.fulfill()
        }
        wait(for: [loadPaymentMethodInfo], timeout: 5.0)
    }

    func testLoadPaymentMethodInfo_singleBankAccount() throws {
        let stubbedAPIClient = stubbedAPIClient()
        StubbedBackend.stubSessions(fileMock: .elementsSessionsLegacyCustomer_di_withSavedUSBank_200,
                                    paymentMethods: "\"us_bank_account\"",
                                    requestCallback: { request in
            guard let requestUrl = request.url else {
                return false
            }
            return requestUrl.absoluteString.contains("legacy_customer_ephemeral_key")
        })
        StubbedBackend.stubSessions(fileMock: .elementsSessionsPaymentMethod_200,
                                    paymentMethods: "\"us_bank_account\"",
                                    requestCallback: { request in
            guard let requestUrl = request.url else {
                return false
            }
            return !requestUrl.absoluteString.contains("legacy_customer_ephemeral_key")
        })

        let configuration = CustomerSheet.Configuration()
        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: "cus_123", ephemeralKeySecret: "ek_456")
        }, setupIntentClientSecretProvider: {
            return "si_789"
        }, apiClient: stubbedAPIClient)

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)
        customerSheet.loadPaymentMethodInfo { result in
            guard case .success((let paymentMethods, let selectedPaymentMethod, let merchantSupportedPaymentMethodTypes)) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(paymentMethods.count, 1)
            XCTAssertEqual(paymentMethods[0].type, .USBankAccount)
            XCTAssert(selectedPaymentMethod == nil)
            XCTAssertEqual(merchantSupportedPaymentMethodTypes, [.USBankAccount])
            loadPaymentMethodInfo.fulfill()
        }
        wait(for: [loadPaymentMethodInfo], timeout: 5.0)
    }

    func testLoadPaymentMethodInfo_cardAndBankAccount() throws {
        let stubbedAPIClient = stubbedAPIClient()
        StubbedBackend.stubSessions(fileMock: .elementsSessionsPaymentMethod_200,
                                    paymentMethods: "\"card\", \"us_bank_account\"",
                                    requestCallback: { request in
            guard let requestUrl = request.url else {
                return false
            }
            return !requestUrl.absoluteString.contains("legacy_customer_ephemeral_key")
        })

        StubbedBackend.stubSessions(fileMock: .elementsSessionsLegacyCustomer_di_withSavedCardUSBank_200,
                                    paymentMethods: "\"card\", \"us_bank_account\"",
                                    requestCallback: { request in
            guard let requestUrl = request.url else {
                return false
            }
            return requestUrl.absoluteString.contains("legacy_customer_ephemeral_key")
        })

        let configuration = CustomerSheet.Configuration()
        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: "cus_123", ephemeralKeySecret: "ek_456")
        }, setupIntentClientSecretProvider: {
            return "si_789"
        }, apiClient: stubbedAPIClient)

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)
        customerSheet.loadPaymentMethodInfo { result in
            guard case .success((let paymentMethods, let selectedPaymentMethod, _)) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(paymentMethods.count, 2)
            XCTAssertEqual(paymentMethods[0].type, .card)
            XCTAssertEqual(paymentMethods[1].type, .USBankAccount)
            XCTAssert(selectedPaymentMethod == nil)
            loadPaymentMethodInfo.fulfill()
        }
        wait(for: [loadPaymentMethodInfo], timeout: 5.0)
    }

    func testLoadPaymentMethodInfo_CallToPaymentMethodsTimesOut() throws {
        let fastTimeoutIntervalForRequest: TimeInterval = 1
        let timeGreaterThanTimeoutIntervalForRequest: UInt32 = 3

        let stubbedURLSessionConfig = APIStubbedTestCase.stubbedURLSessionConfig()
        stubbedURLSessionConfig.timeoutIntervalForRequest = fastTimeoutIntervalForRequest
        let stubbedAPIClient = stubbedAPIClient(configuration: stubbedURLSessionConfig)
        StubbedBackend.stubSessions(fileMock: .elementsSessionsPaymentMethod_200,
                                    paymentMethods: "\"card\"",
                                    requestCallback: { request in
            guard let requestUrl = request.url else {
                return false
            }
            return !requestUrl.absoluteString.contains("legacy_customer_ephemeral_key")
        })

        StubbedBackend.stubSessions(fileMock: .elementsSessionsLegacyCustomer_di_withNoSavedPM_200,
                                    paymentMethods: "\"card\"",
                                    requestCallback: { request in
            guard let requestUrl = request.url else {
                return false
            }
            return requestUrl.absoluteString.contains("legacy_customer_ephemeral_key")
        }, responseCallback: { _ in
            sleep(timeGreaterThanTimeoutIntervalForRequest)
            return "{}".data(using: .utf8)!
        })

        let configuration = CustomerSheet.Configuration()
        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: "cus_123", ephemeralKeySecret: "ek_456")
        }, setupIntentClientSecretProvider: {
            return "si_789"
        }, apiClient: stubbedAPIClient)

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completion block called")
        let customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)
        customerSheet.loadPaymentMethodInfo { result in
            guard case .failure(let error) = result,
                  let nserror = error as NSError?,
                  nserror.code == NSURLErrorTimedOut,
                  nserror.domain == NSURLErrorDomain else {
                XCTFail()
                return
            }
            loadPaymentMethodInfo.fulfill()
        }
        wait(for: [loadPaymentMethodInfo], timeout: 10.0)
    }
}
