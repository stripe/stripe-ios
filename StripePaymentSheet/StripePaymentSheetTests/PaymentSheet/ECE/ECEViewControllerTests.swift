//
//  ECEViewControllerTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import WebKit
import XCTest

#if !os(visionOS)
@available(iOS 16.0, *)
@MainActor
class ECEViewControllerTests: XCTestCase {

    var sut: ECEViewController!
    var mockAPIClient: STPAPIClient!
    var mockDelegate: MockExpressCheckoutWebviewDelegate!

    override func setUp() {
        super.setUp()
        mockAPIClient = STPAPIClient(publishableKey: "pk_test_123")
        mockDelegate = MockExpressCheckoutWebviewDelegate()
        sut = ECEViewController(apiClient: mockAPIClient,
                                shopId: "shop_id_123",
                                customerSessionClientSecret: "cuss_12345")
        sut.expressCheckoutWebviewDelegate = mockDelegate
    }

    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        mockDelegate = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(sut.apiClient)
        XCTAssertEqual(sut.apiClient.publishableKey, "pk_test_123")
    }

    // MARK: - View Lifecycle Tests

    func testViewDidLoad_ConfiguresWebView() {
        // When
        sut.loadViewIfNeeded()

        // Then
        XCTAssertNotNil(sut.view)
        XCTAssertEqual(sut.view.backgroundColor, .systemBackground)

        // Check that webview is added as subview
        let webViews = sut.view.subviews.compactMap { $0 as? WKWebView }
        XCTAssertEqual(webViews.count, 1)

        // Check webview properties
        let webView = webViews.first!
        XCTAssertEqual(webView.frame.width, 1)
        XCTAssertEqual(webView.frame.height, 1)
        XCTAssertFalse(webView.isHidden)
        XCTAssertTrue(webView.alpha <= 0.01)
        XCTAssertEqual(webView.customUserAgent, ECEViewController.FakeSafariUserAgent)
    }

    // MARK: - Message Handler Tests

    func testHandleMessage_CalculateShipping() async throws {
        // Given
        let shippingAddress: [String: Any] = [
            "name": "Test User",
            "address": [
                "city": "San Francisco",
                "state": "CA",
                "postalCode": "94103",
                "country": "US",
            ],
        ]
        let message = MockWKScriptMessage(
            name: "calculateShipping",
            body: ["shippingAddress": shippingAddress]
        )

        mockDelegate.shippingAddressResponse = [
            "lineItems": [["name": "Test Item", "amount": 1000]],
            "shippingRates": [["id": "rate1", "displayName": "Standard", "amount": 500]],
            "totalAmount": 1500,
        ]

        // When
        let response = try await sut.handleMessage(message: message)

        // Then
        XCTAssertNotNil(response)
        let responseDict = response as? [String: Any]
        XCTAssertNil(responseDict?["error"])
        XCTAssertEqual(responseDict?["totalAmount"] as? Int, 1500)

        XCTAssertTrue(mockDelegate.didReceiveShippingAddressChangeCalled)
        XCTAssertNotNil(mockDelegate.lastShippingAddress)
    }

    func testHandleMessage_CalculateShippingRateChange() async throws {
        // Given
        let shippingRate: [String: Any] = ["id": "rate1", "displayName": "Express", "amount": 1000]
        let message = MockWKScriptMessage(
            name: "calculateShippingRateChange",
            body: ["shippingRate": shippingRate]
        )

        mockDelegate.shippingRateResponse = [
            "lineItems": [],
            "shippingRates": [],
            "totalAmount": 2000,
        ]

        // When
        let response = try await sut.handleMessage(message: message)

        // Then
        XCTAssertNotNil(response)
        let responseDict = response as? [String: Any]
        XCTAssertNil(responseDict?["error"])
        XCTAssertEqual(responseDict?["totalAmount"] as? Int, 2000)

        XCTAssertTrue(mockDelegate.didReceiveShippingRateChangeCalled)
        XCTAssertEqual(mockDelegate.lastShippingRate?["id"] as? String, "rate1")
    }

    func testHandleMessage_ConfirmPayment() async throws {
        // Given
        let paymentDetails: [String: Any] = [
            "billingDetails": ["email": "test@example.com", "name": "Test User"],
            "shippingAddress": ["address1": "123 Main St"],
        ]
        let message = MockWKScriptMessage(
            name: "confirmPayment",
            body: ["paymentDetails": paymentDetails]
        )

        mockDelegate.confirmationResponse = [
            "status": "success",
            "requiresAction": false,
        ]

        // When
        let response = try await sut.handleMessage(message: message)

        // Then
        XCTAssertNotNil(response)
        let responseDict = response as? [String: Any]
        XCTAssertEqual(responseDict?["status"] as? String, "success")

        XCTAssertTrue(mockDelegate.didReceiveECEConfirmationCalled)

        let lastBillingDetails = mockDelegate.lastPaymentDetails?["billingDetails"] as? [String: Any]
        XCTAssertEqual(lastBillingDetails?["email"] as? String, "test@example.com")
    }

    func testHandleMessage_InvalidMessageFormat() async {
        // Given
        let message = MockWKScriptMessage(
            name: "calculateShipping",
            body: "invalid body" // Not a dictionary
        )

        // When/Then
        do {
            _ = try await sut.handleMessage(message: message)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Invalid message format"))
        }
    }

    func testHandleMessage_MissingDelegate() async {
        // Given
        sut.expressCheckoutWebviewDelegate = nil
        let message = MockWKScriptMessage(
            name: "calculateShipping",
            body: ["shippingAddress": [:]]
        )

        // When/Then
        do {
            _ = try await sut.handleMessage(message: message)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("ExpressCheckoutWebviewDelegate not set"))
        }
    }

    // MARK: - UI Delegate Tests

    func testCreateWebView_CreatesPopupCorrectly() {
        // Given
        sut.loadViewIfNeeded()
        let configuration = WKWebViewConfiguration()
        let navigationAction = MockWKNavigationAction()

        // When
        let popupWebView = sut.webView(
            WKWebView(),
            createWebViewWith: configuration,
            for: navigationAction,
            windowFeatures: WKWindowFeatures()
        )

        // Then
        XCTAssertNotNil(popupWebView)
        XCTAssertEqual(popupWebView?.frame, sut.view.bounds)
        XCTAssertEqual(popupWebView?.customUserAgent, ECEViewController.FakeSafariUserAgent)
    }
}
#endif
