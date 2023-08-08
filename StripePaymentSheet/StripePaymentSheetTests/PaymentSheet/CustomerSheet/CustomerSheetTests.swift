//
//  CustomerSheetTests.swift
//  StripePaymentSheetTests
//

import Foundation

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments
@_spi(PrivateBetaCustomerSheet) @testable import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

class CustomerSheetTests: APIStubbedTestCase {

    func testLoadPaymentMethodInfo_newCustomer() throws {
        let stubbedAPIClient = stubbedAPIClient()
        stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "card")
        stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "us_bank_account")
        stubSessions(paymentMethods: "\"card\"")

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
        stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "us_bank_account")
        stubSessions(paymentMethods: "\"card\"")

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
        stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "card")
        stubPaymentMethods(fileMock: .saved_payment_methods_withUSBank_200, pmType: "us_bank_account")
        stubSessions(paymentMethods: "\"us_bank_account\"")

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
        stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        stubPaymentMethods(fileMock: .saved_payment_methods_withUSBank_200, pmType: "us_bank_account")
        stubSessions(paymentMethods: "\"card\", \"us_bank_account\"")

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
        stubSessions(paymentMethods: "\"card\"")

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

    private func stubSessions(paymentMethods: String) {
        stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                return self.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": paymentMethods,
                        "<currency>": "\"usd\"",
                    ]
                )
            }
        )
    }

    private func updatePaymentMethodDetail(data: Data, variables: [String: String]) -> Data {
        var template = String(data: data, encoding: .utf8)!
        for (templateKey, templateValue) in variables {
            let translated = template.replacingOccurrences(of: templateKey, with: templateValue)
            template = translated
        }
        return template.data(using: .utf8)!
    }
    private func stubSessions(fileMock: FileMock, responseCallback: ((Data) -> Data)? = nil) {
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/elements/sessions") ?? false
        } response: { _ in
            let mockResponseData = try! fileMock.data()
            let data = responseCallback?(mockResponseData) ?? mockResponseData
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }
    }

    private func stubPaymentMethods(
        fileMock: FileMock,
        pmType: String
    ) {
        stub { urlRequest in
            let isPaymentMethodCall = urlRequest.url?.absoluteString.contains("/v1/payment_methods") ?? false
            let isPaymentMethodType = urlRequest.url?.absoluteString.contains("type=\(pmType)") ?? false
            return (isPaymentMethodCall && isPaymentMethodType)
        } response: { _ in
            let mockResponseData = try! fileMock.data()
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }
    }
}

public class ClassForBundle {}
@_spi(STP) public enum FileMock: String, MockData {
    public typealias ResponseType = StripeFile
    public var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case saved_payment_methods_200 = "MockFiles/saved_payment_methods_200"
    case saved_payment_methods_withCard_200 = "MockFiles/saved_payment_methods_withCard_200"
    case saved_payment_methods_withUSBank_200 = "MockFiles/saved_payment_methods_withUSBank_200"

    case elementsSessionsPaymentMethod_200 = "MockFiles/elements_sessions_paymentMethod_200"
}
