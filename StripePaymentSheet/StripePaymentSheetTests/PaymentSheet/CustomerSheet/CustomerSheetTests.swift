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
        stubNewCustomerResponse()

        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: "cus_123", ephemeralKeySecret: "ek_456")
        }, setupIntentClientSecretProvider: {
            return "si_789"
        }, apiClient: stubbedAPIClient)

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: CustomerSheet.Configuration(), customer: customerAdapter)
        customerSheet.loadPaymentMethodInfo { result in
            guard case .success((let paymentMethods, let selectedPaymentMethod)) = result else {
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
        stubReturningCustomerWithCardResponse()

        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: "cus_123", ephemeralKeySecret: "ek_456")
        }, setupIntentClientSecretProvider: {
            return "si_789"
        }, apiClient: stubbedAPIClient)

        let loadPaymentMethodInfo = expectation(description: "loadPaymentMethodInfo completed")
        let customerSheet = CustomerSheet(configuration: CustomerSheet.Configuration(), customer: customerAdapter)
        customerSheet.loadPaymentMethodInfo { result in
            guard case .success((let paymentMethods, let selectedPaymentMethod)) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(paymentMethods.count, 1)
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
        let customerSheet = CustomerSheet(configuration: CustomerSheet.Configuration(), customer: customerAdapter)
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
        wait(for: [loadPaymentMethodInfo], timeout: 5.0)
    }

    private func stubNewCustomerResponse() {
        stubPaymentMethods(fileMock: .saved_payment_methods_200)
    }

    private func stubReturningCustomerWithCardResponse() {
        stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200)
    }

    private func stubPaymentMethods(
        fileMock: FileMock
    ) {
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/payment_methods") ?? false
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
}
