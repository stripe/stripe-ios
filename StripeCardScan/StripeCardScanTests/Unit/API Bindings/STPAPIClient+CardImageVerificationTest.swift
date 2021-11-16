//
//  STPAPIClient+CardImageVerificationTest.swift
//  StripeCardScanTests
//
//  Created by Jaime Park on 11/16/21.
//

@testable import StripeCardScan
@testable @_spi(STP) import StripeCore
import StripeCoreTestUtils
import OHHTTPStubs
import XCTest

class STPAPIClient_CardImageVerificationTest: APIStubbedTestCase {
    let cardImageVerificationId = "civ_1234"
    let cardImageVerificationClientSecret = "civ_client_secret_1234"

    /**
     The following test is mocking a flow where the merchant has set a card during the CIV intent creation.
     It will check the following:
     1. Request URL has been constructed properly: /v1/card_image_verifications/:id/initialize_client?client_secret=:secret
     2. Response from request has details of card set during the CIV intent creation
     */
    func testGetCardImageVerificationDetails_CardSet() throws {
        let mockResponse = try CardImageVerificationDetailsResponseMock.cardImageVerification_cardSet_200.data()

        // Stub the request to get details of CIV intent
        stub { request in
            XCTAssertNotNil(request.url)
            XCTAssertEqual(request.url?.absoluteString.contains("v1/card_image_verifications/\(self.cardImageVerificationId)/initialize_client"), true)
            XCTAssertEqual(request.url?.query?.contains("client_secret=\(self.cardImageVerificationClientSecret)"), true)
            XCTAssertEqual(request.httpMethod, "GET")
            return true
        } response: { request in
            return HTTPStubsResponse(data: mockResponse, statusCode: 200, headers: nil)
        }

        let exp = expectation(description: "Request completed")

        // Make request to get card details
        let apiClient = stubbedAPIClient()
        let promise = apiClient.getCardImageVerificationDetails(
            cardImageVerificationSecret: cardImageVerificationClientSecret,
            cardImageVerificationId: cardImageVerificationId
        )

        promise.observe { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.expectedCard?.last4, "4242")
                XCTAssertEqual(response.expectedCard?.issuer, "Visa")
            case .failure(let error):
                XCTFail("Request returned error \(error)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    /**
     The following test is mocking a flow where the merchant has not set a card during the CIV intent creation.
     It will check the following:
     1. Request URL has been constructed properly: /v1/card_image_verifications/:id/initialize_client?client_secret=:secret
     2. Response from request is empty
     */
    func testGetCardImageVerificationDetails_CardAdd() throws {
        let mockResponse = try CardImageVerificationDetailsResponseMock.cardImageVerification_cardAdd_200.data()

        // Stub the request to get details of CIV intent
        stub { request in
            XCTAssertNotNil(request.url)
            XCTAssertEqual(request.url?.absoluteString.contains("v1/card_image_verifications/\(self.cardImageVerificationId)/initialize_client"), true)
            XCTAssertEqual(request.url?.query?.contains("client_secret=\(self.cardImageVerificationClientSecret)"), true)
            XCTAssertEqual(request.httpMethod, "GET")
            return true
        } response: { request in
            return HTTPStubsResponse(data: mockResponse, statusCode: 200, headers: nil)
        }

        let exp = expectation(description: "Request completed")

        // Make request to get card details
        let apiClient = stubbedAPIClient()
        let promise = apiClient.getCardImageVerificationDetails(
            cardImageVerificationSecret: cardImageVerificationClientSecret,
            cardImageVerificationId: cardImageVerificationId
        )

        promise.observe { result in
            switch result {
            case .success(let response):
                XCTAssertNil(response.expectedCard)
            case .failure(let error):
                XCTFail("Request returned error \(error)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }
}
