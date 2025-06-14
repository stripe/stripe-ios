//
//  ECEViewControllerTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import WebKit
import XCTest

#if !canImport(CompositorServices)
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
        sut = ECEViewController(apiClient: mockAPIClient)
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
        XCTAssertEqual(webView.frame.width, 500) // TODO: Will be 1x1 in production
        XCTAssertEqual(webView.frame.height, 500)
        XCTAssertFalse(webView.isHidden)
        XCTAssertEqual(webView.alpha, 1.0) // TODO: Will be 0.01 in production
        XCTAssertEqual(webView.customUserAgent, ECEViewController.FakeSafariUserAgent)
    }

    func testNavigationBarSetup() {
        // When
        sut.loadViewIfNeeded()

        // Then
        XCTAssertEqual(sut.title, "Checkout")
        XCTAssertNotNil(sut.navigationItem.rightBarButtonItem)
        XCTAssertEqual(sut.navigationItem.leftBarButtonItems?.count, 2)
    }

    // MARK: - WebView Configuration Tests

    func testWebViewConfiguration() {
        // When
        sut.loadViewIfNeeded()

        // Get the webview
        let webView = sut.view.subviews.compactMap { $0 as? WKWebView }.first!
        let configuration = webView.configuration

        // Then
        XCTAssertTrue(configuration.defaultWebpagePreferences.allowsContentJavaScript)
        XCTAssertTrue(configuration.preferences.javaScriptCanOpenWindowsAutomatically)

        // Check message handlers are registered
        let userContentController = configuration.userContentController
        // Note: WKUserContentController doesn't expose a way to check registered handlers,
        // so we'll test this indirectly through integration tests
    }

    // MARK: - Message Handler Tests

    func testHandleMessage_CalculateShipping() async throws {
        // Given
        let shippingAddress = [
            "address1": "123 Main St",
            "city": "San Francisco",
            "countryCode": "US",
        ]
        let message = MockWKScriptMessage(
            name: "calculateShipping",
            body: ["shippingAddress": shippingAddress]
        )

        mockDelegate.shippingAddressResponse = [
            "merchantDecision": "accepted",
            "lineItems": [["name": "Test Item", "amount": 1000]],
            "shippingRates": [["id": "rate1", "displayName": "Standard", "amount": 500]],
            "totalAmount": 1500,
        ]

        // When
        let response = try await sut.handleMessage(message: message)

        // Then
        XCTAssertNotNil(response)
        let responseDict = response as? [String: Any]
        XCTAssertEqual(responseDict?["merchantDecision"] as? String, "accepted")
        XCTAssertEqual(responseDict?["totalAmount"] as? Int, 1500)

        XCTAssertTrue(mockDelegate.didReceiveShippingAddressChangeCalled)
        XCTAssertEqual(mockDelegate.lastShippingAddress as? [String: String], shippingAddress)
    }

    func testHandleMessage_CalculateShippingRateChange() async throws {
        // Given
        let shippingRate: [String: Any] = ["id": "rate1", "displayName": "Express", "amount": 1000]
        let message = MockWKScriptMessage(
            name: "calculateShippingRateChange",
            body: ["shippingRate": shippingRate]
        )

        mockDelegate.shippingRateResponse = [
            "merchantDecision": "accepted"
        ]

        // When
        let response = try await sut.handleMessage(message: message)

        // Then
        XCTAssertNotNil(response)
        let responseDict = response as? [String: Any]
        XCTAssertEqual(responseDict?["merchantDecision"] as? String, "accepted")

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

        // Check close button was added
        let closeButton = popupWebView?.subviews.first { $0.tag == 999 } as? UIButton
        XCTAssertNotNil(closeButton)
    }
}
#endif
