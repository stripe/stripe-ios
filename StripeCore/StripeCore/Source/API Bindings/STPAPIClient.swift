//
//  STPAPIClient.swift
//  StripeExample
//
//  Created by Jack Flintermann on 12/18/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

import Foundation
import UIKit

/// A client for making connections to the Stripe API.
public class STPAPIClient {
    /// The current version of this library.
    public static let STPSDKVersion = StripeAPIConfiguration.STPSDKVersion

    /// A shared singleton API client.
    /// By default, the SDK uses this instance to make API requests
    /// eg in STPPaymentHandler, STPPaymentContext, STPCustomerContext, etc.
    public static let shared: STPAPIClient = {
        let client = STPAPIClient()
        STPAnalyticsClient.sharedClient.publishableKeyProvider = client
        return client
    }()

    /// The client's publishable key.
    /// The default value is `StripeAPI.defaultPublishableKey`.
    public var publishableKey: String? {
        get {
            if let publishableKey = _publishableKey {
                return publishableKey
            }
            return StripeAPI.defaultPublishableKey
        }
        set {
            _publishableKey = newValue
            Self.validateKey(newValue)
        }
    }
    var _publishableKey: String?

    // Stored STPPaymentConfiguration: Type checking handled in STPAPIClient+Payments.swift
    @_spi(STP) public var _stored_configuration: NSObject?
    
    /// In order to perform API requests on behalf of a connected account, e.g. to
    /// create a Source or Payment Method on a connected account, set this property to the ID of the
    /// account for which this request is being made.
    /// - seealso: https://stripe.com/docs/connect/authentication#authentication-via-the-stripe-account-header
    public var stripeAccount: String?

    /// Libraries wrapping the Stripe SDK should set this, so that Stripe can contact you about future issues or critical updates.
    /// - seealso: https://stripe.com/docs/building-plugins#setappinfo
    public var appInfo: STPAppInfo?

    /// The API version used to communicate with Stripe.
    public static let apiVersion = APIVersion

    // MARK: Internal/private properties
    @_spi(STP) public var apiURL: URL! = URL(string: APIBaseURL)
    @_spi(STP) public var urlSession = URLSession(configuration: StripeAPIConfiguration.sharedUrlSessionConfiguration)

    @_spi(STP) public var sourcePollers: [String: NSObject]?
    @_spi(STP) public var sourcePollersQueue: DispatchQueue?
    /// A set of beta headers to add to Stripe API requests e.g. `Set(["alipay_beta=v1"])`
    var betas: Set<String> = []
    
    /// Returns `true` if `publishableKey` is actually a user key, `false` otherwise.
    @_spi(STP) public var publishableKeyIsUserKey: Bool {
        return publishableKey?.hasPrefix("uk_") ?? false
    }

    // MARK: Initializers
    public init() {
        sourcePollers = [:]
        sourcePollersQueue = DispatchQueue(label: "com.stripe.sourcepollers")
    }

    /// Initializes an API client with the given publishable key.
    /// - Parameter publishableKey: The publishable key to use.
    /// - Returns: An instance of STPAPIClient.
    public convenience init(publishableKey: String) {
        self.init()
        self.publishableKey = publishableKey
    }

    @_spi(STP) public func configuredRequest(for url: URL, additionalHeaders: [String: String] = [:])
        -> NSMutableURLRequest
    {
        let request = NSMutableURLRequest(url: url)
        var headers = defaultHeaders()
        for (k, v) in additionalHeaders { headers[k] = v }  // additionalHeaders can overwrite defaultHeaders
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }

    /// Headers common to all API requests for a given API Client.
    func defaultHeaders() -> [String: String] {
        var defaultHeaders: [String: String] = [:]
        defaultHeaders["X-Stripe-User-Agent"] = STPAPIClient.stripeUserAgentDetails(with: appInfo)
        var stripeVersion = APIVersion
        for beta in betas {
            stripeVersion = stripeVersion + "; \(beta)"
        }
        defaultHeaders["Stripe-Version"] = stripeVersion
        defaultHeaders["Stripe-Account"] = stripeAccount
        for (k, v) in authorizationHeader() { defaultHeaders[k] = v }
        return defaultHeaders
    }

    // MARK: Helpers

    static var didShowTestmodeKeyWarning = false
    class func validateKey(_ publishableKey: String?) {
        guard let publishableKey = publishableKey, !publishableKey.isEmpty else {
            assertionFailure(
                "You must use a valid publishable key. For more info, see https://stripe.com/docs/keys"
            )
            return
        }
        let secretKey = publishableKey.hasPrefix("sk_")
        assert(
            !secretKey,
            "You are using a secret key. Use a publishable key instead. For more info, see https://stripe.com/docs/keys"
        )
        #if !DEBUG
            if publishableKey.lowercased().hasPrefix("pk_test") && !didShowTestmodeKeyWarning {
                print(
                    "ℹ️ You're using your Stripe testmode key. Make sure to use your livemode key when submitting to the App Store!"
                )
                didShowTestmodeKeyWarning = true
            }
        #endif
    }

    @_spi(STP) public static var paymentUserAgent: String {
        var paymentUserAgent = "stripe-ios/\(STPAPIClient.STPSDKVersion)"
        let components = [paymentUserAgent] + STPAnalyticsClient.sharedClient.productUsage
        paymentUserAgent = components.joined(separator: "; ")
        return paymentUserAgent
    }
    
    @_spi(STP) public class func paramsAddingPaymentUserAgent(_ params: [String: Any]) -> [String: Any] {
        var newParams = params
        newParams["payment_user_agent"] = Self.paymentUserAgent
        return newParams
    }
    
    class func stripeUserAgentDetails(with appInfo: STPAppInfo?) -> String {
        var details: [String: String] = [
            "lang": "objective-c",
            "bindings_version": STPSDKVersion,
        ]
        let version = UIDevice.current.systemVersion
        if version != "" {
            details["os_version"] = version
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        
        // Thanks to https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let deviceType = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        details["type"] = deviceType
        let model = UIDevice.current.localizedModel
        if model != "" {
            details["model"] = model
        }

        let vendorIdentifier = UIDevice.current.identifierForVendor?.uuidString
        if let vendorIdentifier = vendorIdentifier {
            details["vendor_identifier"] = vendorIdentifier
        }
        if let appInfo = appInfo {
            details["name"] = appInfo.name
            details["partner_id"] = appInfo.partnerId
            if appInfo.version != nil {
                details["version"] = appInfo.version
            }
            if appInfo.url != nil {
                details["url"] = appInfo.url
            }
        }
        let data = try? JSONSerialization.data(withJSONObject: details, options: [])
        return String(data: data ?? Data(), encoding: .utf8) ?? ""
    }
    
    @_spi(STP) public func authorizationHeader(using ephemeralKeySecret: String? = nil) -> [String: String] {
        var authorizationBearer = publishableKey ?? ""
        if let ephemeralKeySecret = ephemeralKeySecret {
            authorizationBearer = ephemeralKeySecret
        }
        var headers: [String: String] = [
            "Authorization": "Bearer " + authorizationBearer
        ]
        if publishableKeyIsUserKey {
            if ProcessInfo.processInfo.environment["Stripe-Livemode"] == "false" {
                headers["Stripe-Livemode"] = "false"
            } else {
                headers["Stripe-Livemode"] = "true"
            }
        }
        return headers
    }
  
  @_spi(STP) public var isTestmode: Bool {
    guard let publishableKey = publishableKey, !publishableKey.isEmpty else {
      return false
    }
    return publishableKey.lowercased().hasPrefix("pk_test")
  }

}

/// :nodoc:
@_spi(STP) extension STPAPIClient: PublishableKeyProvider { }

private let APIVersion = "2020-08-27"
private let APIBaseURL = "https://api.stripe.com/v1"
