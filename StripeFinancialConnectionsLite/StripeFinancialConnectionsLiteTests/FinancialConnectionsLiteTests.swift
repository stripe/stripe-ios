//
//  FinancialConnectionsLiteTests.swift
//  StripeFinancialConnectionsLiteTests
//

@_spi(STP) import StripeCore
@testable @_spi(STP) import StripeFinancialConnectionsLite
import XCTest

class FinancialConnectionsLiteTests: XCTestCase {

    func testUsesProvidedAPIClient() {
        // Given a custom API client
        let customClient = STPAPIClient(publishableKey: "pk_test_custom")

        // When constructing FinancialConnectionsLite with it
        let fcLite = FinancialConnectionsLite(
            clientSecret: "las_123",
            returnUrl: URL(string: "stripe://return"),
            apiClient: customClient
        )

        // Then that client is stored (rather than falling back to .shared)
        XCTAssertTrue(fcLite.apiClient === customClient)
    }

    func testDefaultsToSharedAPIClient() {
        // Given no explicit API client
        let fcLite = FinancialConnectionsLite(clientSecret: "las_123", returnUrl: nil)

        // Then it defaults to the shared client
        XCTAssertTrue(fcLite.apiClient === STPAPIClient.shared)
    }

    func testStoresConsumerKeyAndPrefillDetails() {
        // Given a FinancialConnectionsLite instance
        let fcLite = FinancialConnectionsLite(clientSecret: "las_123", returnUrl: nil)

        // When setting the consumer key and prefill details
        fcLite.consumerPublishableKey = "pk_consumer"
        fcLite.prefillDetails = WebPrefillDetails(
            email: "test@example.com",
            phone: "5551234567",
            countryCode: "US"
        )

        // Then they are stored
        XCTAssertEqual(fcLite.consumerPublishableKey, "pk_consumer")
        XCTAssertEqual(fcLite.prefillDetails?.email, "test@example.com")
        XCTAssertEqual(fcLite.prefillDetails?.phone, "5551234567")
        XCTAssertEqual(fcLite.prefillDetails?.countryCode, "US")
    }

    func testPresentEmbeddedInReplacesStackInPlace() {
        // Given a navigation controller that's never been presented
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let fcLite = FinancialConnectionsLite(clientSecret: "las_123", returnUrl: nil)

        // When embedding the flow into it
        fcLite.present(embeddedIn: navigationController) { _ in }

        // Then the stack is replaced in place with FC Lite's own container, and no new modal is presented
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers.first is FCLiteContainerViewController)
        XCTAssertTrue(navigationController.isNavigationBarHidden)
        XCTAssertNil(navigationController.presentedViewController)
    }

    func testPresentEmbeddedInCallsCompletionWithoutDismissing() {
        // Given a navigation controller embedded with FC Lite
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let fcLite = FinancialConnectionsLite(clientSecret: "las_123", returnUrl: nil)
        var receivedResult: FinancialConnectionsSDKResult?
        fcLite.present(embeddedIn: navigationController) { result in
            receivedResult = result
        }

        // When the flow completes
        let completionExpectation = expectation(description: "completion fires")
        fcLite.handleFlowCompletion(result: .cancelled)
        DispatchQueue.main.async {
            completionExpectation.fulfill()
        }
        wait(for: [completionExpectation], timeout: 1)

        // Then the completion handler fires directly (no presented view controller to dismiss)
        switch receivedResult {
        case .cancelled:
            break
        default:
            XCTFail("Expected .cancelled, got \(String(describing: receivedResult))")
        }
    }
}
