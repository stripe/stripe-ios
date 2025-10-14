//
//  ECETestHelpers.swift
//  StripePaymentSheetTests
//

import Foundation
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import WebKit
import XCTest

// MARK: - Mock Web View Components

@available(iOS 16.0, *)
class MockWKSecurityOrigin: NSObject {
    private let _host: String
    private let _protocol: String
    private let _port: Int

    init(host: String, protocol: String = "https", port: Int = 443) {
        self._host = host
        self._protocol = `protocol`
        self._port = port
        super.init()
    }

    @objc var host: String {
        return _host
    }

    @objc var `protocol`: String {
        return _protocol
    }

    @objc var port: Int {
        return _port
    }
}

@available(iOS 16.0, *)
class MockWKFrameInfo: WKFrameInfo {
    private let _request: URLRequest
    private let _isMainFrame: Bool
    private let _securityOrigin: NSObject

    init(request: URLRequest, isMainFrame: Bool = true, securityOrigin: NSObject? = nil) {
        self._request = request
        self._isMainFrame = isMainFrame
        self._securityOrigin = securityOrigin ?? MockWKSecurityOrigin(host: "pay.stripe.com")
        super.init()
    }

    override var request: URLRequest {
        return _request
    }

    override var isMainFrame: Bool {
        return _isMainFrame
    }

    override var securityOrigin: WKSecurityOrigin {
        return unsafeBitCast(_securityOrigin, to: WKSecurityOrigin.self)
    }
}

// MARK: - Shared Mock Classes

@available(iOS 16.0, *)
class MockExpressCheckoutWebviewDelegate: ExpressCheckoutWebviewDelegate {
    var amountToReturn = 1000
    var shippingAddressResponse: [String: Any] = [
        "lineItems": [],
        "shippingRates": [],
        "totalAmount": 1000,
    ]
    var shippingRateResponse: [String: Any] = [
        "lineItems": [],
        "shippingRates": [],
        "totalAmount": 1000,
    ]
    var clickEventResponse: [String: Any] = [
        "lineItems": [],
        "billingAddressRequired": true,
        "emailRequired": true,
        "phoneNumberRequired": true,
        "shippingAddressRequired": true,
        "business": ["name": "Test Business"],
        "allowedShippingCountries": ["US"],
        "shopId": "test_shop",
    ]
    var confirmationResponse: [String: Any] = [
        "status": "success",
        "requiresAction": false,
    ]

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
    private let _frameInfo: WKFrameInfo

    init(name: String, body: Any, frameInfo: WKFrameInfo? = nil) {
        self._name = name
        self._body = body
        self._frameInfo = frameInfo ?? MockWKFrameInfo(
            request: URLRequest(url: URL(string: "https://pay.stripe.com")!),
            isMainFrame: true,
            securityOrigin: MockWKSecurityOrigin(host: "pay.stripe.com")
        )
        super.init()
    }

    override var name: String {
        return _name
    }

    override var body: Any {
        return _body
    }

    override var frameInfo: WKFrameInfo {
        return _frameInfo
    }
}

@available(iOS 16.0, *)
class MockWKNavigationAction: WKNavigationAction {
    var mockRequest = URLRequest(url: URL(string: "https://test.com")!)

    override var request: URLRequest {
        return mockRequest
    }
}
