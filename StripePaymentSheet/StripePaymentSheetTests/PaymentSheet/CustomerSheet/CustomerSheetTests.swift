//
//  CustomerSheetTests.swift
//  StripePaymentSheetTests
//

import Foundation

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments
@_spi(CustomerSessionBetaAccess) @_spi(CardBrandFilteringBeta) @_spi(AllowsSetAsDefaultPM) @testable import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

class CustomerSheetTests: APIStubbedTestCase {

    func testLoadPaymentMethodInfo_newCustomer() throws {
        let stubbedAPIClient = stubbedAPIClient()
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")
        StubbedBackend.stubSessions(paymentMethods: "\"card\"")

        let configuration = CustomerSheet.Configuration()
        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: "cus_123", ephemeralKeySecret: "ek_456")
        }, setupIntentClientSecretProvider: {
            return "si_789"
        }, apiClient: stubbedAPIClient)

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)
        let csDataSource = customerSheet.createCustomerSheetDataSource()!
        csDataSource.loadPaymentMethodInfo { result in
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
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")
        StubbedBackend.stubSessions(paymentMethods: "\"card\"")

        let configuration = CustomerSheet.Configuration()
        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: "cus_123", ephemeralKeySecret: "ek_456")
        }, setupIntentClientSecretProvider: {
            return "si_789"
        }, apiClient: stubbedAPIClient)

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)
        let csDataSource = customerSheet.createCustomerSheetDataSource()!
        csDataSource.loadPaymentMethodInfo { result in
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
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withUSBank_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")
        StubbedBackend.stubSessions(paymentMethods: "\"us_bank_account\"")

        let configuration = CustomerSheet.Configuration()
        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: "cus_123", ephemeralKeySecret: "ek_456")
        }, setupIntentClientSecretProvider: {
            return "si_789"
        }, apiClient: stubbedAPIClient)

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)
        let csDataSource = customerSheet.createCustomerSheetDataSource()!
        csDataSource.loadPaymentMethodInfo { result in
            guard case .success((let paymentMethods, let selectedPaymentMethod, let elementsSession)) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(paymentMethods.count, 1)
            XCTAssertEqual(paymentMethods[0].type, .USBankAccount)
            XCTAssert(selectedPaymentMethod == nil)
            XCTAssertEqual(elementsSession.orderedPaymentMethodTypes, [.USBankAccount])
            loadPaymentMethodInfo.fulfill()
        }
        wait(for: [loadPaymentMethodInfo], timeout: 5.0)
    }

    func testLoadPaymentMethodInfo_cardAndBankAccount() throws {
        let stubbedAPIClient = stubbedAPIClient()
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withUSBank_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")

        StubbedBackend.stubSessions(paymentMethods: "\"card\", \"us_bank_account\"")

        let configuration = CustomerSheet.Configuration()
        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: "cus_123", ephemeralKeySecret: "ek_456")
        }, setupIntentClientSecretProvider: {
            return "si_789"
        }, apiClient: stubbedAPIClient)

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)
        let csDataSource = customerSheet.createCustomerSheetDataSource()!
        csDataSource.loadPaymentMethodInfo { result in
            guard case .success((let paymentMethods, let selectedPaymentMethod, _)) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(paymentMethods.count, 2)
            XCTAssert(paymentMethods[0].type == .card && paymentMethods[1].type == .USBankAccount ||
                      paymentMethods[1].type == .card && paymentMethods[0].type == .USBankAccount)
            XCTAssert(selectedPaymentMethod == nil)
            loadPaymentMethodInfo.fulfill()
        }
        wait(for: [loadPaymentMethodInfo], timeout: 5.0)
    }

    func testLoadPaymentMethodInfo_cardAndSepa() throws {
        let stubbedAPIClient = stubbedAPIClient()
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withSepa_200, pmType: "sepa_debit")
        StubbedBackend.stubSessions(paymentMethods: "\"card\", \"sepa_debit\"")

        let configuration = CustomerSheet.Configuration()
        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: "cus_123", ephemeralKeySecret: "ek_456")
        }, setupIntentClientSecretProvider: {
            return "si_789"
        }, apiClient: stubbedAPIClient)

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)
        let csDataSource = customerSheet.createCustomerSheetDataSource()!
        csDataSource.loadPaymentMethodInfo { result in
            guard case .success((let paymentMethods, let selectedPaymentMethod, _)) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(paymentMethods.count, 2)
            XCTAssert(paymentMethods[0].type == .card && paymentMethods[1].type == .SEPADebit ||
                      paymentMethods[1].type == .card && paymentMethods[0].type == .SEPADebit)
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
        StubbedBackend.stubSessions(paymentMethods: "\"card\"")

        let configuration = CustomerSheet.Configuration()
        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: "cus_123", ephemeralKeySecret: "ek_456")
        }, setupIntentClientSecretProvider: {
            return "si_789"
        }, apiClient: stubbedAPIClient)

        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/payment_methods") ?? false
        } response: { _ in
            sleep(timeGreaterThanTimeoutIntervalForRequest)
            let data = "{}".data(using: .utf8)!
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completion block called")
        let customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)
        let csDataSource = customerSheet.createCustomerSheetDataSource()!
        csDataSource.loadPaymentMethodInfo { result in
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
    
    func testLoadPaymentMethodInfo_filtersCard() throws {
        let stubbedAPIClient = stubbedAPIClient()
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")
        StubbedBackend.stubSessions(paymentMethods: "\"card\"")

        var configuration = CustomerSheet.Configuration()
        configuration.cardBrandAcceptance = .disallowed(brands: [.visa])
        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: "cus_123", ephemeralKeySecret: "ek_456")
        }, setupIntentClientSecretProvider: {
            return "si_789"
        }, apiClient: stubbedAPIClient)

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)
        let csDataSource = customerSheet.createCustomerSheetDataSource()!
        csDataSource.loadPaymentMethodInfo { result in
            guard case .success((let paymentMethods, _, _)) = result else {
                XCTFail()
                return
            }
            // Card should be filtered out since it is a Visa
            XCTAssertTrue(paymentMethods.isEmpty)
            loadPaymentMethodInfo.fulfill()
        }
        wait(for: [loadPaymentMethodInfo], timeout: 5.0)
    }

    func testLoadPaymentMethodInfo_CustomerSession() throws {
        let stubbedAPIClient = stubbedAPIClient()
        StubbedBackend.stubSessions(fileMock: .elementsSessions_customerSessionsCustomerSheet_200)
        var configuration = CustomerSheet.Configuration()
        configuration.apiClient = stubbedAPIClient

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration,
                                          intentConfiguration: .init(setupIntentClientSecretProvider: { return "si_123" }),
                                          customerSessionClientSecretProvider: { return .init(customerId: "cus_123", clientSecret: "cuss_123") })
        let csDataSource = customerSheet.createCustomerSheetDataSource()!
        csDataSource.loadPaymentMethodInfo { result in
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

    func testLoadPaymentMethodInfo_CustomerSessionWithSavedPM() throws {
        let stubbedAPIClient = stubbedAPIClient()
        StubbedBackend.stubSessions(fileMock: .elementsSessions_customerSessionsCustomerSheetWithSavedPM_200)
        var configuration = CustomerSheet.Configuration()
        configuration.apiClient = stubbedAPIClient

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration,
                                          intentConfiguration: .init(setupIntentClientSecretProvider: { return "si_123" }),
                                          customerSessionClientSecretProvider: { return .init(customerId: "cus_123", clientSecret: "cuss_123") })
        let csDataSource = customerSheet.createCustomerSheetDataSource()!
        csDataSource.loadPaymentMethodInfo { result in
            guard case .success((let paymentMethods, let selectedPaymentMethod, _)) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(paymentMethods.count, 1)
            XCTAssert(selectedPaymentMethod == nil)
            loadPaymentMethodInfo.fulfill()
        }
        wait(for: [loadPaymentMethodInfo], timeout: 5.0)
    }

    func testLoadPaymentMethodInfo_CustomerSessionFailsClaim() throws {
        let stubbedAPIClient = stubbedAPIClient()
        StubbedBackend.stubSessions(paymentMethods: "\"card\"")
        var configuration = CustomerSheet.Configuration()
        configuration.apiClient = stubbedAPIClient

        let expectedFailure = expectation(description: "loadPaymentMethodInfo failed")
        let customerSheet = CustomerSheet(configuration: configuration,
                                          intentConfiguration: .init(setupIntentClientSecretProvider: { return "si_123" }),
                                          customerSessionClientSecretProvider: { return .init(customerId: "cus_123", clientSecret: "cuss_123") })
        let csDataSource = customerSheet.createCustomerSheetDataSource()!
        csDataSource.loadPaymentMethodInfo { result in
            guard case .failure = result else {
                XCTFail()
                return
            }
            expectedFailure.fulfill()
        }
        wait(for: [expectedFailure], timeout: 5.0)
    }
    
    func testLoadPaymentMethodInfo_CustomerSessionFiltersSavedCard() throws {
        let stubbedAPIClient = stubbedAPIClient()
        StubbedBackend.stubSessions(fileMock: .elementsSessions_customerSessionsCustomerSheetWithSavedPM_200)
        var configuration = CustomerSheet.Configuration()
        configuration.apiClient = stubbedAPIClient
        configuration.cardBrandAcceptance = .disallowed(brands: [.visa])
        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration,
                                          intentConfiguration: .init(setupIntentClientSecretProvider: { return "si_123" }),
                                          customerSessionClientSecretProvider: { return .init(customerId: "cus_123", clientSecret: "cuss_123") })
        let csDataSource = customerSheet.createCustomerSheetDataSource()!
        csDataSource.loadPaymentMethodInfo { result in
            guard case .success((let paymentMethods, _, _)) = result else {
                XCTFail()
                return
            }
            XCTAssertTrue(paymentMethods.isEmpty)
            loadPaymentMethodInfo.fulfill()
        }
        wait(for: [loadPaymentMethodInfo], timeout: 5.0)
    }

    func testLoadPaymentMethodInfo_CustomerSession_NoDefaultPMHasSavedPaymentMethod() throws {
        let stubbedAPIClient = stubbedAPIClient()
        StubbedBackend.stubSessions(fileMock: .elementsSessions_customerSessionsCustomerSheetWithSavedPM_200)
        var configuration = CustomerSheet.Configuration()
        configuration.apiClient = stubbedAPIClient
        configuration.allowsSetAsDefaultPM = true

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration,
                                          intentConfiguration: .init(setupIntentClientSecretProvider: { return "si_123" }),
                                          customerSessionClientSecretProvider: { return .init(customerId: "cus_123", clientSecret: "cuss_123") })
        let csDataSource = customerSheet.createCustomerSheetDataSource()!
        csDataSource.loadPaymentMethodInfo { result in
            guard case .success((let paymentMethods, let selectedPaymentMethod, _)) = result else {
                XCTFail()
                return
            }
            XCTAssertFalse(paymentMethods.isEmpty)
            XCTAssertNotNil(selectedPaymentMethod)
            loadPaymentMethodInfo.fulfill()
        }
        wait(for: [loadPaymentMethodInfo], timeout: 5.0)
    }

    func testLoadPaymentMethodInfo_CustomerSession_NoDefaultPMNoSavedPaymentMethod() throws {
        let stubbedAPIClient = stubbedAPIClient()
        StubbedBackend.stubSessions(fileMock: .elementsSessions_customerSessionsCustomerSheet_200)
        var configuration = CustomerSheet.Configuration()
        configuration.apiClient = stubbedAPIClient
        configuration.allowsSetAsDefaultPM = true

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: configuration,
                                          intentConfiguration: .init(setupIntentClientSecretProvider: { return "si_123" }),
                                          customerSessionClientSecretProvider: { return .init(customerId: "cus_123", clientSecret: "cuss_123") })
        let csDataSource = customerSheet.createCustomerSheetDataSource()!
        csDataSource.loadPaymentMethodInfo { result in
            guard case .success((let paymentMethods, let selectedPaymentMethod, _)) = result else {
                XCTFail()
                return
            }
            XCTAssertTrue(paymentMethods.isEmpty)
            XCTAssertNil(selectedPaymentMethod)
            loadPaymentMethodInfo.fulfill()
        }
        wait(for: [loadPaymentMethodInfo], timeout: 5.0)
    }
}
