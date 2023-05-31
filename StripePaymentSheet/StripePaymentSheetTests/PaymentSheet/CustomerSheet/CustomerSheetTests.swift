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

    func testLoadPaymentMethodInfo_CallToPaymentMethodsTimesOut() throws {
        let customerId = "cus_123"
        let ephemeralKey = "ek_456"
        let setupIntentClientSecret = "si_789"
        let fastTimeoutIntervalForRequest: TimeInterval = 1
        let timeGreaterThanTimeoutIntervalForRequest: UInt32 = 3

        let stubbedURLSessionConfig = APIStubbedTestCase.stubbedURLSessionConfig()
        stubbedURLSessionConfig.timeoutIntervalForRequest = fastTimeoutIntervalForRequest
        let stubbedAPIClient = stubbedAPIClient(configuration: stubbedURLSessionConfig)

        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            .init(customerId: customerId, ephemeralKeySecret: ephemeralKey)
        }, setupIntentClientSecretProvider: {
            return setupIntentClientSecret
        }, apiClient: stubbedAPIClient)

        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/payment_methods") ?? false
        } response: { _ in
            sleep(timeGreaterThanTimeoutIntervalForRequest)
            let data = "{}".data(using: .utf8)!
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }

        let loadPaymentMethodCalled = expectation(description: "load called")
        let customerSheet = CustomerSheet(configuration: CustomerSheet.Configuration(), customer: customerAdapter)
        customerSheet.loadPaymentMethodInfo { result in
            guard case .failure(let error) = result,
            let nserror = error as NSError?,
                nserror.code == NSURLErrorTimedOut,
            nserror.domain == NSURLErrorDomain else {
                return
            }
            loadPaymentMethodCalled.fulfill()
        }
        wait(for: [loadPaymentMethodCalled], timeout: 5.0)
    }
}
