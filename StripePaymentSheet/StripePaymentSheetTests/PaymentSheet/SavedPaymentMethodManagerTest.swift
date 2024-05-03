//
//  SavedPaymentMethodManagerTest.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/3/24.
//

import Foundation
import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP)@_spi(CustomerSessionBetaAccess)@testable import StripePaymentSheet
import StripeCoreTestUtils

final class SavedPaymentMethodManagerTests: XCTestCase {
    
    let ephemeralKey = "test-eph-key"
    let paymentMethod = STPPaymentMethod.stubbedPaymentMethod()
    
    var configuration: PaymentSheet.Configuration {
        let apiClient = APIStubbedTestCase.stubbedAPIClient()
        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = apiClient
        return configuration
    }
    
    // MARK: Update tests
    func testUpdatePaymentMethod() async throws {
        let paymentMethod = STPPaymentMethod.stubbedPaymentMethod()
        let expectation = stubUpdatePaymentMethod(paymentMethod: paymentMethod,
                                ephemeralKey: ephemeralKey)
        
        let sut = SavedPaymentMethodManager(configuration: configuration)
        let updatedPaymentMethod = try await sut.update(paymentMethod: paymentMethod,
                           with: STPPaymentMethodUpdateParams(),
                           using: ephemeralKey)
        
        // Verify the response was valid
        XCTAssertEqual("pm_123card", updatedPaymentMethod.stripeId)
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: Detach tests
    func testDetachPaymentMethod_noCustomer() {
        let expectation = stubDetachPaymentMethod(paymentMethod: STPPaymentMethod.stubbedPaymentMethod(),
                                                  ephemeralKey: ephemeralKey)
        
        let sut = SavedPaymentMethodManager(configuration: configuration)
        sut.detach(paymentMethod: paymentMethod, using: ephemeralKey)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDetachPaymentMethod_withLegacyCustomer() {
        var configuration = configuration
        configuration.customer = .init(id: "cus_test123", ephemeralKeySecret: ephemeralKey)
        
        
        let expectation = stubDetachPaymentMethod(paymentMethod: STPPaymentMethod.stubbedPaymentMethod(),
                                                  ephemeralKey: ephemeralKey)
        
        let sut = SavedPaymentMethodManager(configuration: configuration)
        sut.detach(paymentMethod: paymentMethod, using: ephemeralKey)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDetachPaymentMethod_withCustomerSession() {
        var configuration = configuration
        configuration.customer = .init(id: "cus_test123", customerSessionClientSecret: "session_123")

        let listPaymentMethodsExpectation = stubListPaymentMethods(customerId: configuration.customer!.id,
                                                                   ephemeralKey: ephemeralKey)
        
        let detachExpectation = stubDetachPaymentMethod(paymentMethod: STPPaymentMethod.stubbedPaymentMethod(),
                                                  ephemeralKey: ephemeralKey)

        
        let sut = SavedPaymentMethodManager(configuration: configuration)
        sut.detach(paymentMethod: paymentMethod, using: ephemeralKey)
        
        wait(for: [listPaymentMethodsExpectation, detachExpectation], timeout: 5.0)
    }
}

extension SavedPaymentMethodManagerTests {
    // MARK: HTTP Stubs
    
    func stubRequest(urlContains: String,
                     ephemeralKey: String,
                     httpMethod: String,
                     responseObject: Any) -> XCTestExpectation {
        let exp = expectation(description: "Request \(httpMethod) \(urlContains)")

        stub { urlRequest in
          return urlRequest.url?.absoluteString.contains(urlContains) ?? false
            && urlRequest.allHTTPHeaderFields?["Authorization"] == "Bearer \(ephemeralKey)"
            && urlRequest.httpMethod == httpMethod
        } response: { _ in
            DispatchQueue.main.async {
                exp.fulfill()
            }
            return HTTPStubsResponse(jsonObject: responseObject,
                                     statusCode: 200,
                                     headers: nil)
        }

        return exp
    }

    func stubUpdatePaymentMethod(paymentMethod: STPPaymentMethod, ephemeralKey: String) -> XCTestExpectation {
        return stubRequest(urlContains: "/payment_methods/\(paymentMethod.stripeId)",
                           ephemeralKey: ephemeralKey,
                           httpMethod: "POST",
                           responseObject: STPPaymentMethod.paymentMethodJson)
    }

    func stubDetachPaymentMethod(paymentMethod: STPPaymentMethod, ephemeralKey: String) -> XCTestExpectation {
        return stubRequest(urlContains: "/payment_methods/\(paymentMethod.stripeId)/detach",
                           ephemeralKey: ephemeralKey,
                           httpMethod: "POST",
                           responseObject: [:])
    }

    func stubListPaymentMethods(customerId: String, ephemeralKey: String) -> XCTestExpectation {
        return stubRequest(urlContains: "/payment_methods?customer=\(customerId)&type=card",
                           ephemeralKey: ephemeralKey,
                           httpMethod: "GET",
                           responseObject: STPPaymentMethod.paymentMethodsJson)
    }
}

extension STPPaymentMethod {
    
    static var paymentMethodJson: [String: Any] {
        return [
            "id": "pm_123card",
            "type": "card",
            "card": [
                "last4": "4242",
                "brand": "visa",
            ],
        ]
    }
    
    static var paymentMethodsJson: [String: Any] = [
        "data": [
            [
                "id": "pm_123card",
                "type": "card",
                "card": [
                    "last4": "4242",
                    "brand": "visa",
                ],
            ],
            [
                "id": "pm_123mastercard",
                "type": "card",
                "card": [
                    "last4": "5555",
                    "brand": "mastercard",
                ],
            ],
            [
                "id": "pm_123amex",
                "type": "card",
                "card": [
                    "last4": "6789",
                    "brand": "amex",
                ],
            ]
        ]
    ]
    
    /// Creates a fake payment method for tests
    static func stubbedPaymentMethod() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: paymentMethodJson)!
    }
}
