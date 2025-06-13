//
//  ECEViewControllerTests.swift
//  StripePaymentSheetTests
//

import XCTest
import WebKit
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet

@available(iOS 16.0, *)
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
        XCTAssertEqual(sut.navigationItem.rightBarButtonItem?.systemItem, .refresh)
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
            "countryCode": "US"
        ]
        let message = MockWKScriptMessage(
            name: "calculateShipping",
            body: ["shippingAddress": shippingAddress]
        )
        
        mockDelegate.shippingAddressResponse = [
            "merchantDecision": "accepted",
            "lineItems": [["name": "Test Item", "amount": 1000]],
            "shippingRates": [["id": "rate1", "displayName": "Standard", "amount": 500]],
            "totalAmount": 1500
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
        let shippingRate = ["id": "rate1", "displayName": "Express", "amount": 1000]
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
        XCTAssertEqual(mockDelegate.lastShippingRate as? [String: Any], shippingRate)
    }
    
    func testHandleMessage_ConfirmPayment() async throws {
        // Given
        let paymentDetails = [
            "billingDetails": ["email": "test@example.com", "name": "Test User"],
            "shippingAddress": ["address1": "123 Main St"]
        ]
        let message = MockWKScriptMessage(
            name: "confirmPayment",
            body: ["paymentDetails": paymentDetails]
        )
        
        mockDelegate.confirmationResponse = [
            "status": "success",
            "requiresAction": false
        ]
        
        // When
        let response = try await sut.handleMessage(message: message)
        
        // Then
        XCTAssertNotNil(response)
        let responseDict = response as? [String: Any]
        XCTAssertEqual(responseDict?["status"] as? String, "success")
        
        XCTAssertTrue(mockDelegate.didReceiveECEConfirmationCalled)
        XCTAssertEqual(mockDelegate.lastPaymentDetails as? [String: Any], paymentDetails)
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
    
    // MARK: - Navigation Delegate Tests
    
    func testWebViewDidFinish_CallsInitializeApp() {
        // Given
        let mockWebView = MockWKWebView()
        mockWebView.mockURL = URL(string: "https://pay.stripe.com/test")
        
        // When
        sut.webView(mockWebView, didFinish: nil)
        
        // Then
        XCTAssertTrue(mockWebView.evaluateJavaScriptCalled)
        XCTAssertEqual(mockWebView.lastJavaScript, "initializeApp()")
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

// MARK: - Mock Classes

@available(iOS 16.0, *)
class MockExpressCheckoutWebviewDelegate: ExpressCheckoutWebviewDelegate {
    var amountToReturn = 1000
    var shippingAddressResponse: [String: Any] = [:]
    var shippingRateResponse: [String: Any] = [:]
    var clickEventResponse: [String: Any] = [:]
    var confirmationResponse: [String: Any] = [:]
    
    var didReceiveShippingAddressChangeCalled = false
    var didReceiveShippingRateChangeCalled = false
    var didReceiveECEClickCalled = false
    var didReceiveECEConfirmationCalled = false
    
    var lastShippingAddress: [String: Any]?
    var lastShippingRate: [String: Any]?
    var lastClickEvent: [String: Any]?
    var lastPaymentDetails: [String: Any]?
    
    func amountForECEView(_ eceView: ECEViewController) -> Int {
        return amountToReturn
    }
    
    func eceView(_ eceView: ECEViewController, didReceiveShippingAddressChange shippingAddress: [String: Any]) async throws -> [String: Any] {
        didReceiveShippingAddressChangeCalled = true
        lastShippingAddress = shippingAddress
        return shippingAddressResponse
    }
    
    func eceView(_ eceView: ECEViewController, didReceiveShippingRateChange shippingRate: [String: Any]) async throws -> [String: Any] {
        didReceiveShippingRateChangeCalled = true
        lastShippingRate = shippingRate
        return shippingRateResponse
    }
    
    func eceView(_ eceView: ECEViewController, didReceiveECEClick event: [String: Any]) async throws -> [String: Any] {
        didReceiveECEClickCalled = true
        lastClickEvent = event
        return clickEventResponse
    }
    
    func eceView(_ eceView: ECEViewController, didReceiveECEConfirmation paymentDetails: [String: Any]) async throws -> [String: Any] {
        didReceiveECEConfirmationCalled = true
        lastPaymentDetails = paymentDetails
        return confirmationResponse
    }
}

@available(iOS 16.0, *)
class MockWKScriptMessage: WKScriptMessage {
    private let _name: String
    private let _body: Any
    
    init(name: String, body: Any) {
        self._name = name
        self._body = body
        super.init()
    }
    
    override var name: String {
        return _name
    }
    
    override var body: Any {
        return _body
    }
}

@available(iOS 16.0, *)
class MockWKWebView: WKWebView {
    var mockURL: URL?
    var evaluateJavaScriptCalled = false
    var lastJavaScript: String?
    
    override var url: URL? {
        return mockURL
    }
    
    override func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        evaluateJavaScriptCalled = true
        lastJavaScript = javaScriptString
        completionHandler?(nil, nil)
    }
}

@available(iOS 16.0, *)
class MockWKNavigationAction: WKNavigationAction {
    var mockRequest = URLRequest(url: URL(string: "https://test.com")!)
    
    override var request: URLRequest {
        return mockRequest
    }
} 