//
//  STPAPIClient.swift
//  StripeCore
//
//  Created by Jack Flintermann on 12/18/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// A client for making connections to the Stripe API.
@objc public class STPAPIClient: NSObject {
    /// The current version of this library.
    @objc public static let STPSDKVersion = StripeAPIConfiguration.STPSDKVersion

    /// A shared singleton API client.
    ///
    /// By default, the SDK uses this instance to make API requests
    /// eg in STPPaymentHandler, STPPaymentContext, STPCustomerContext, etc.
    @objc(sharedClient) public static let shared: STPAPIClient = {
        let client = STPAPIClient()
        return client
    }()

    /// The client's publishable key.
    ///
    /// The default value is `StripeAPI.defaultPublishableKey`.
    @objc public var publishableKey: String? {
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

    /// A publishable key that only contains publishable keys and not secret keys.
    ///
    /// If a secret key is found, returns "[REDACTED_LIVE_KEY]".
    @_spi(STP) public var sanitizedPublishableKey: String? {
        guard let publishableKey = publishableKey else {
            return nil
        }

        return publishableKey.sanitizedKey
    }

    // Stored STPPaymentConfiguration: Type checking handled in STPAPIClient+Payments.swift.
    @_spi(STP) public var _stored_configuration: NSObject?

    /// In order to perform API requests on behalf of a connected account, e.g. to
    /// create a Source or Payment Method on a connected account, set this property to the ID of the
    /// account for which this request is being made.
    ///
    /// - seealso: https://stripe.com/docs/connect/authentication#authentication-via-the-stripe-account-header
    @objc public var stripeAccount: String?

    /// Libraries wrapping the Stripe SDK should set this, so that Stripe can contact you
    /// about future issues or critical updates.
    ///
    /// - seealso: https://stripe.com/docs/building-plugins#setappinfo
    @objc public var appInfo: STPAppInfo?

    /// The API version used to communicate with Stripe.
    @objc public static let apiVersion = APIVersion

    // MARK: Internal/private properties
    @_spi(STP) public var apiURL: URL! = URL(string: APIBaseURL)
    @_spi(STP) public var urlSession = URLSession(
        configuration: StripeAPIConfiguration.sharedUrlSessionConfiguration
    )

    @_spi(STP) public var sourcePollers: [String: NSObject]?
    @_spi(STP) public var sourcePollersQueue: DispatchQueue?
    /// A set of beta headers to add to Stripe API requests e.g. `Set(["alipay_beta=v1"])`.
    @_spi(STP) public var betas: Set<String> = []

    /// Returns `true` if `publishableKey` is actually a user key, `false` otherwise.
    @_spi(STP) public var publishableKeyIsUserKey: Bool {
        return publishableKey?.hasPrefix("uk_") ?? false
    }

    /// Determines the `Stripe-Livemode` header value when the publishable key is a user key
    @_spi(DashboardOnly) public var userKeyLiveMode = true

    @_spi(STP) public lazy var stripeAttest: StripeAttest = StripeAttest(apiClient: self)

    // MARK: Initializers
    override public init() {
        sourcePollers = [:]
        sourcePollersQueue = DispatchQueue(label: "com.stripe.sourcepollers")
    }

    /// Initializes an API client with the given publishable key.
    ///
    /// - Parameter publishableKey: The publishable key to use.
    /// - Returns: An instance of STPAPIClient.
    @objc(initWithPublishableKey:)
    public convenience init(
        publishableKey: String
    ) {
        self.init()
        self.publishableKey = publishableKey
    }

    @_spi(STP) public func configuredRequest(
        for url: URL,
        using ephemeralKeySecret: String? = nil,
        additionalHeaders: [String: String] = [:]
    )
        -> URLRequest
    {
        var request = URLRequest(url: url)
        var headers = defaultHeaders(ephemeralKeySecret: ephemeralKeySecret)
        // additionalHeaders can overwrite defaultHeaders.
        for (k, v) in additionalHeaders { headers[k] = v }
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }

    /// Headers common to all API requests for a given API Client.
    func defaultHeaders(ephemeralKeySecret: String?) -> [String: String] {
        var defaultHeaders: [String: String] = [:]
        defaultHeaders["X-Stripe-User-Agent"] = STPAPIClient.stripeUserAgentDetails(with: appInfo)
        var stripeVersion = APIVersion
        for beta in betas {
            stripeVersion += "; \(beta)"
        }
        defaultHeaders["Stripe-Version"] = stripeVersion
        defaultHeaders["Stripe-Account"] = stripeAccount
        for (k, v) in authorizationHeader(using: ephemeralKeySecret) { defaultHeaders[k] = v }
        return defaultHeaders
    }

    // MARK: Helpers

    static var didShowTestmodeKeyWarning = false
    @_spi(STP) public class func validateKey(_ publishableKey: String?) {
        guard NSClassFromString("XCTest") == nil else {
            return  // no asserts in unit tests
        }
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

    class func stripeUserAgentDetails(with appInfo: STPAppInfo?) -> String {
        var details: [String: String] = [
            // This SDK isn't in Objective-C anymore, but we sometimes check for
            // 'objective-c' to enable iOS SDK-specific behavior in the API.
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

        if let vendorIdentifier = UIDevice.current.identifierForVendor?.uuidString {
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

    @_spi(STP) public func authorizationHeader(
        using substituteAuthorizationBearer: String? = nil
    ) -> [String: String] {
        let authorizationBearer = substituteAuthorizationBearer ?? publishableKey ?? ""
        var headers = ["Authorization": "Bearer " + authorizationBearer]

        if publishableKeyIsUserKey {
            headers["Stripe-Livemode"] = userKeyLiveMode ? "true" : "false"
        }
        return headers
    }

    @_spi(STP) public var isTestmode: Bool {
        guard let publishableKey = publishableKey, !publishableKey.isEmpty else {
            return false
        }
        return publishableKey.lowercased().hasPrefix("pk_test") || (publishableKeyIsUserKey && !userKeyLiveMode)
    }

    /**
     Copies the api client.
     - Note: This should be used in cases where you need to make a request
     using the same configuration as a given STPAPIClient , but need to make a
     modification such as overriding beta headers or `stripeAccount`.
     */
    @_spi(STP) public func makeCopy() -> STPAPIClient {
        let client = STPAPIClient()
        client._publishableKey = _publishableKey
        client._stored_configuration = _stored_configuration
        client.stripeAccount = stripeAccount
        client.appInfo = appInfo
        client.apiURL = apiURL
        client.urlSession = urlSession
        client.betas = betas
        client.userKeyLiveMode = userKeyLiveMode
        return client
    }
}

private let APIVersion = "2020-08-27"
private let APIBaseURL = "https://api.stripe.com/v1"

// MARK: Modern bindings
extension STPAPIClient {
    /// Make a GET request using the passed parameters.
    @_spi(STP) public func get<T: Decodable>(
        resource: String,
        parameters: [String: Any],
        ephemeralKeySecret: String? = nil,
        consumerPublishableKey: String? = nil,
        completion: @escaping (
            Result<T, Error>
        ) -> Void
    ) {
        request(
            method: .get,
            parameters: parameters,
            ephemeralKeySecret: ephemeralKeySecret,
            consumerPublishableKey: consumerPublishableKey,
            resource: resource,
            completion: completion
        )
    }

    /// Make a GET request using the passed parameters.
    @_spi(STP) public func get<T: Decodable>(
        url: URL,
        parameters: [String: Any],
        ephemeralKeySecret: String? = nil,
        consumerPublishableKey: String? = nil,
        completion: @escaping (
            Result<T, Error>
        ) -> Void
    ) {
        request(
            method: .get,
            parameters: parameters,
            ephemeralKeySecret: ephemeralKeySecret,
            consumerPublishableKey: consumerPublishableKey,
            url: url,
            completion: completion
        )
    }

    /// Make a GET request using the passed parameters.
    ///
    /// - Returns: a promise that is fullfilled when the request is complete.
    @_spi(STP) public func get<T: Decodable>(
        resource: String,
        parameters: [String: Any],
        ephemeralKeySecret: String? = nil,
        consumerPublishableKey: String? = nil
    ) -> Promise<T> {
        return request(
            method: .get,
            parameters: parameters,
            ephemeralKeySecret: ephemeralKeySecret,
            consumerPublishableKey: consumerPublishableKey,
            resource: resource
        )
    }

    /// Make a POST request using the passed parameters.
    @_spi(STP) public func post<T: Decodable>(
        resource: String,
        parameters: [String: Any],
        ephemeralKeySecret: String? = nil,
        consumerPublishableKey: String? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        request(
            method: .post,
            parameters: parameters,
            ephemeralKeySecret: ephemeralKeySecret,
            consumerPublishableKey: consumerPublishableKey,
            resource: resource,
            completion: completion
        )
    }

    /// Make a POST request using the passed parameters.
    @_spi(STP) public func post<T: Decodable>(
        url: URL,
        parameters: [String: Any],
        ephemeralKeySecret: String? = nil,
        consumerPublishableKey: String? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        request(
            method: .post,
            parameters: parameters,
            ephemeralKeySecret: ephemeralKeySecret,
            consumerPublishableKey: consumerPublishableKey,
            url: url,
            completion: completion
        )
    }

    /// Make a POST request using the passed parameters.
    ///
    /// - Returns: a promise that is fullfilled when the request is complete.
    @_spi(STP) public func post<T: Decodable>(
        resource: String,
        parameters: [String: Any],
        ephemeralKeySecret: String? = nil,
        consumerPublishableKey: String? = nil
    ) -> Promise<T> {
        return request(
            method: .post,
            parameters: parameters,
            ephemeralKeySecret: ephemeralKeySecret,
            consumerPublishableKey: consumerPublishableKey,
            resource: resource
        )
    }

    func request<T: Decodable>(
        method: HTTPMethod,
        parameters: [String: Any],
        ephemeralKeySecret: String?,
        consumerPublishableKey: String?,
        resource: String
    ) -> Promise<T> {
        let promise = Promise<T>()
        self.request(
            method: method,
            parameters: parameters,
            ephemeralKeySecret: ephemeralKeySecret,
            consumerPublishableKey: consumerPublishableKey,
            resource: resource
        ) { result in
            promise.fullfill(with: result)
        }
        return promise
    }

    func request<T: Decodable>(
        method: HTTPMethod,
        parameters: [String: Any],
        ephemeralKeySecret: String?,
        consumerPublishableKey: String?,
        resource: String,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let url = apiURL.appendingPathComponent(resource)
        request(
            method: method,
            parameters: parameters,
            ephemeralKeySecret: ephemeralKeySecret,
            consumerPublishableKey: consumerPublishableKey,
            url: url,
            completion: completion
        )
    }

    func request<T: Decodable>(
        method: HTTPMethod,
        parameters: [String: Any],
        ephemeralKeySecret: String?,
        consumerPublishableKey: String?,
        url: URL,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        var request = configuredRequest(for: url)
        switch method {
        case .get:
            request.stp_addParameters(toURL: parameters)
        case .post:
            let formData = URLEncoder.queryString(from: parameters).data(using: .utf8)
            request.httpBody = formData
            request.setValue(
                String(format: "%lu", UInt(formData?.count ?? 0)),
                forHTTPHeaderField: "Content-Length"
            )
            request.setValue(
                "application/x-www-form-urlencoded",
                forHTTPHeaderField: "Content-Type"
            )
            #if DEBUG
            if StripeAPIConfiguration.includeDebugParamsHeader {
                request.setValue(URLEncoder.queryString(from: parameters), forHTTPHeaderField: "X-Stripe-Mock-Request")
            }
            #endif
        }

        request.httpMethod = method.rawValue
        for (k, v) in authorizationHeader(using: ephemeralKeySecret ?? consumerPublishableKey) {
            request.setValue(v, forHTTPHeaderField: k)
        }

        if consumerPublishableKey != nil {
            // If we now have a consumer publishable key, we no longer send the connected account
            // in the header, as otherwise the request will justifiably fail.
            request.setValue(nil, forHTTPHeaderField: "Stripe-Account")
        }

        self.sendRequest(request: request, completion: completion)
    }

    /// Make a POST request using the passed Encodable object.
    ///
    /// - Returns: a promise that is fullfilled when the request is complete.
    @_spi(STP) public func post<I: Encodable, O: Decodable>(
        resource: String,
        object: I,
        ephemeralKeySecret: String? = nil
    ) -> Promise<O> {
        let promise = Promise<O>()
        self.post(
            resource: resource,
            object: object,
            ephemeralKeySecret: ephemeralKeySecret
        ) { result in
            promise.fullfill(with: result)
        }
        return promise
    }

    /// Make a POST request using the passed Encodable object.
    @_spi(STP) public func post<I: Encodable, O: Decodable>(
        resource: String,
        object: I,
        ephemeralKeySecret: String? = nil,
        completion: @escaping (Result<O, Error>) -> Void
    ) {
        let url = apiURL.appendingPathComponent(resource)
        post(
            url: url,
            object: object,
            ephemeralKeySecret: ephemeralKeySecret,
            completion: completion
        )
    }

    /// Make a POST request using the passed Encodable object.
    @_spi(STP) public func post<I: Encodable, O: Decodable>(
        url: URL,
        object: I,
        ephemeralKeySecret: String? = nil,
        completion: @escaping (Result<O, Error>) -> Void
    ) {
        do {
            let jsonDictionary = try object.encodeJSONDictionary()
            let formData = URLEncoder.queryString(from: jsonDictionary).data(using: .utf8)
            var request = configuredRequest(
                for: url,
                using: ephemeralKeySecret,
                additionalHeaders: [
                    "Content-Length": String(format: "%lu", UInt(formData?.count ?? 0)),
                    "Content-Type": "application/x-www-form-urlencoded",
                ]
            )
            request.httpBody = formData
            request.httpMethod = HTTPMethod.post.rawValue

            self.sendRequest(request: request, completion: completion)
        } catch {
            // JSONEncoder can only throw two possible exceptions:
            // `invalidFloatingPointValue`, which will never be thrown because of
            // our encoder's NonConformingFloatEncodingStrategy.
            // The other is `invalidValue` if the top-level object doesn't encode any values.
            // This should ~never happen, and if it does the object will be empty,
            // so it should be safe to return the un-redacted underlying error.
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }

    func sendRequest<T: Decodable>(
        request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        urlSession.stp_performDataTask(
            with: request,
            completionHandler: { (data, response, error) in
                DispatchQueue.main.async {
                    completion(
                        STPAPIClient.decodeResponse(data: data, error: error, response: response, request: request)
                    )
                }
            }
        )
    }

    @_spi(STP) public static func decodeResponse<T: Decodable>(
        data: Data?,
        error: Error?,
        response: URLResponse?,
        request: URLRequest? = nil
    ) -> Result<T, Error> {
        if let error = error {
            return .failure(error)
        }
        guard let data = data else {
            return .failure(NSError.stp_genericFailedToParseResponseError())
        }

        do {
            #if DEBUG
            if let httpResponse = response as? HTTPURLResponse,
               let method = request?.httpMethod,
               let requestId = httpResponse.value(forHTTPHeaderField: "request-id"),
               let url = httpResponse.value(forKey: "URL") as? URL {
                print("[Stripe SDK]: \(method) \"\(url.relativePath)\" \(httpResponse.statusCode) \(requestId)")
            }
            #endif
            // HACK: We must first check if EmptyResponses contain an error since it'll always parse successfully.
            if T.self == EmptyResponse.self,
                let decodedStripeError = decodeStripeErrorResponse(data: data, response: response)
            {
                return .failure(decodedStripeError)
            }

            let decodedObject: T = try StripeJSONDecoder.decode(jsonData: data)
            return .success(decodedObject)
        } catch {
            // Try decoding the error from the service if one is available
            if let decodedStripeError = decodeStripeErrorResponse(data: data, response: response) {
                return .failure(decodedStripeError)
            } else {
                // Return decoding error directly
                return .failure(error)
            }
        }
    }

    /// Decodes request data to see if it can be parsed as a Stripe error.
    static func decodeStripeErrorResponse(
        data: Data,
        response: URLResponse?
    ) -> StripeError? {
        var decodedError: StripeError?

        if let decodedErrorResponse: StripeAPIErrorResponse = try? StripeJSONDecoder.decode(
            jsonData: data
        ),
            var apiError = decodedErrorResponse.error
        {
            apiError.statusCode = (response as? HTTPURLResponse)?.statusCode
            apiError.requestID = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "request-id")

            decodedError = StripeError.apiError(apiError)
        }

        return decodedError
    }

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }
}
