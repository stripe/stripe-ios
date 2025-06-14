//
//  ECETestHelpers.swift
//  StripePaymentSheetTests
//

import Foundation
import XCTest
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import WebKit

// MARK: - Test Data Factories

@available(iOS 16.0, *)
enum ECETestData {

    static func defaultShopPayConfiguration() -> PaymentSheet.ShopPayConfiguration {
        return PaymentSheet.ShopPayConfiguration(
            billingAddressRequired: true,
            emailRequired: true,
            shippingAddressRequired: true,
            lineItems: [
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Test Item 1", amount: 1000),
                PaymentSheet.ShopPayConfiguration.LineItem(name: "Test Item 2", amount: 500),
            ],
            shippingRates: [
                PaymentSheet.ShopPayConfiguration.ShippingRate(
                    id: "standard",
                    amount: 500,
                    displayName: "Standard Shipping",
                    deliveryEstimate: PaymentSheet.ShopPayConfiguration.DeliveryEstimate(
                        minimum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 5, unit: .day),
                        maximum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 7, unit: .day)
                    )
                ),
                PaymentSheet.ShopPayConfiguration.ShippingRate(
                    id: "express",
                    amount: 1500,
                    displayName: "Express Shipping",
                    deliveryEstimate: PaymentSheet.ShopPayConfiguration.DeliveryEstimate(
                        minimum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 1, unit: .day),
                        maximum: PaymentSheet.ShopPayConfiguration.DeliveryEstimate.DeliveryEstimateUnit(value: 2, unit: .day)
                    )
                ),
            ],
            shopId: "test_shop_123",
            allowedShippingCountries: ["US", "CA"]
        )
    }

    static func validShippingAddress(
        firstName: String = "John",
        lastName: String = "Doe",
        city: String = "San Francisco",
        state: String = "CA",
        postalCode: String = "94103",
        country: String = "US"
    ) -> [String: Any] {
        return [
            "firstName": firstName,
            "lastName": lastName,
            "address1": "123 Main St",
            "address2": "Apt 4B",
            "city": city,
            "provinceCode": state,
            "postalCode": postalCode,
            "countryCode": country,
            "companyName": "Test Company",
            "phone": "+14155551234",
            "email": "test@example.com",
        ]
    }

    static func validBillingDetails(
        email: String = "test@example.com",
        phone: String = "+14155551234",
        name: String = "John Doe"
    ) -> [String: Any] {
        return [
            "email": email,
            "phone": phone,
            "name": name,
            "address": [
                "line1": "123 Main St",
                "line2": "Apt 4B",
                "city": "San Francisco",
                "state": "CA",
                "postalCode": "94103",
                "countryCode": "US",
            ],
        ]
    }

    static func shippingRate(id: String) -> [String: Any] {
        switch id {
        case "standard":
            return [
                "id": "standard",
                "displayName": "Standard Shipping",
                "amount": 500,
            ]
        case "express":
            return [
                "id": "express",
                "displayName": "Express Shipping",
                "amount": 1500,
            ]
        default:
            return [
                "id": id,
                "displayName": "Custom Rate",
                "amount": 1000,
            ]
        }
    }
}

// MARK: - Mock Web View Components

@available(iOS 16.0, *)
class MockWKNavigationResponse: WKNavigationResponse {
    private let _response: URLResponse

    init(response: URLResponse) {
        self._response = response
        super.init()
    }

    override var response: URLResponse {
        return _response
    }
}

@available(iOS 16.0, *)
class MockWKFrameInfo: WKFrameInfo {
    private let _request: URLRequest
    private let _isMainFrame: Bool

    init(request: URLRequest, isMainFrame: Bool = true) {
        self._request = request
        self._isMainFrame = isMainFrame
        super.init()
    }

    override var request: URLRequest {
        return _request
    }

    override var isMainFrame: Bool {
        return _isMainFrame
    }
}

// MARK: - Test Assertions

@available(iOS 16.0, *)
struct ECEAssertions {

    static func assertValidShippingResponse(
        _ response: [String: Any],
        expectedDecision: String = "accepted",
        expectedItemCount: Int? = nil,
        expectedRateCount: Int? = nil,
        expectedTotal: Int? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(response["merchantDecision"] as? String, expectedDecision, file: file, line: line)

        if let expectedItemCount = expectedItemCount {
            let lineItems = response["lineItems"] as? [[String: Any]]
            XCTAssertEqual(lineItems?.count, expectedItemCount, file: file, line: line)
        }

        if let expectedRateCount = expectedRateCount {
            let shippingRates = response["shippingRates"] as? [[String: Any]]
            XCTAssertEqual(shippingRates?.count, expectedRateCount, file: file, line: line)
        }

        if let expectedTotal = expectedTotal {
            XCTAssertEqual(response["totalAmount"] as? Int, expectedTotal, file: file, line: line)
        }
    }

    static func assertValidConfirmationResponse(
        _ response: [String: Any],
        expectedStatus: String = "success",
        requiresAction: Bool = false,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(response["status"] as? String, expectedStatus, file: file, line: line)
        XCTAssertEqual(response["requiresAction"] as? Bool, requiresAction, file: file, line: line)
    }
}

// MARK: - WebView Test Utilities

@available(iOS 16.0, *)
class WebViewTestObserver: NSObject {
    private var observations: [String: [Any]] = [:]

    func recordEvent(_ event: String, data: Any? = nil) {
        if observations[event] == nil {
            observations[event] = []
        }
        observations[event]?.append(data ?? NSNull())
    }

    func eventCount(_ event: String) -> Int {
        return observations[event]?.count ?? 0
    }

    func lastEventData(_ event: String) -> Any? {
        return observations[event]?.last
    }

    func reset() {
        observations = [:]
    }
}

// MARK: - Async Test Helpers

@available(iOS 16.0, *)
extension XCTestCase {

    func waitForCondition(
        timeout: TimeInterval = 5.0,
        condition: @escaping () async -> Bool
    ) async throws {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if await condition() {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        XCTFail("Condition not met within timeout")
    }

    func performAsyncTest<T>(
        timeout: TimeInterval = 5.0,
        test: @escaping () async throws -> T
    ) async throws -> T {
        return try await withTimeout(seconds: timeout) {
            try await test()
        }
    }

    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TestTimeoutError()
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

struct TestTimeoutError: Error {
    var localizedDescription: String {
        return "Test operation timed out"
    }
}

// MARK: - JavaScript Injection Helpers

@available(iOS 16.0, *)
extension WKWebView {

    func injectTestScript(_ script: String) async throws {
        _ = try await evaluateJavaScript(script)
    }

    func simulateECEEvent(_ eventName: String, data: [String: Any]) async throws {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        let script = """
        if (window.expressCheckoutElement) {
            const event = new CustomEvent('\(eventName)', { detail: \(jsonString) });
            window.expressCheckoutElement.dispatchEvent(event);
        } else {
            throw new Error('Express Checkout Element not found');
        }
        """

        try await injectTestScript(script)
    }
}

// MARK: - Shared Mock Classes

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

@available(iOS 16.0, *)
class MockPaymentSheetFlowController {
    let configuration: PaymentSheet.Configuration
    let intent: Intent
    
    init(configuration: PaymentSheet.Configuration) {
        self.configuration = configuration
        self.intent = .deferredIntent(intentConfig: PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "USD"),
            confirmHandler: { _, _, completion in
                completion(.success("pm_123"))
            }
        ))
    }
}
