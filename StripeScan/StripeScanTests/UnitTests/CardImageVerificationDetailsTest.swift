//
//  CardImageVerificationDetailsTest.swift
//  CardVerifyTests
//
//  Created by Jaime Park on 9/22/21.
//

// TODO(kingst): add this test back to the Test target after we add dependencies
import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift
@testable import StripeScan

class CardImageVerificationDetailsTest: XCTestCase {
    let cardImageVerificationId = "civ_1234"
    let cardImageVerificationClientSecret = "civ_client_secret_1234"
    let apiClient = STPAPIClient(publishableKey:  "pk_1234")

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    // Checks that initialize client GET request has proper query params
    func testGetCardImageVerificationDetails_QueryParams() {
        let expectation = XCTestExpectation(description: "GetCIVDetails Query Params")

        stub(condition: pathEndsWith("/card_image_verifications/\(cardImageVerificationId)/initialize_client")) { request in
            XCTAssertNotNil(request.url)
            XCTAssertEqual(request.url?.host, "api.stripe.com")
            XCTAssert(request.url?.query?.contains("client_secret=\(self.cardImageVerificationClientSecret)") == true,
                      "Query does not contain client secret")
            defer { expectation.fulfill() }
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: .none)
        }

        apiClient.getCardImageVerificationDetails(
            cardImageVerificationSecret: cardImageVerificationClientSecret,
            cardImageVerificationId: cardImageVerificationId) { _ in }

        wait(for: [expectation], timeout: 1)
    }

    // Checks that the initialize client API request parsing routine is behaving properly
    func testGetCardImageVerificationDetails_Response() throws {
        let expectation = XCTestExpectation(description: "GetCIVDetails Response Parsing")
        let initalizeClientJSONData = try TestData.initializeClient.dataFromJSONFile()

        stub(condition: pathEndsWith("/card_image_verifications/\(cardImageVerificationId)/initialize_client")) { _ in
            return HTTPStubsResponse(
                data: initalizeClientJSONData,
                statusCode: 200,
                headers: .none)
        }

        apiClient.getCardImageVerificationDetails(
            cardImageVerificationSecret: cardImageVerificationClientSecret,
            cardImageVerificationId: cardImageVerificationId)
        { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.expectedCard.last4, "4242")
                XCTAssertEqual(response.expectedCard.issuer, "Visa")
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}
