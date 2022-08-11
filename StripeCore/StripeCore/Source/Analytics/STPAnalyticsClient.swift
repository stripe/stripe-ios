//
//  STPAnalyticsClient.swift
//  StripeCore
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@_spi(STP) public protocol STPAnalyticsProtocol {
    static var stp_analyticsIdentifier: String { get }
}

@_spi(STP) public protocol STPAnalyticsClientProtocol {
    func addClass<T: STPAnalyticsProtocol>(toProductUsageIfNecessary klass: T.Type)
    func log(analytic: Analytic, apiClient: STPAPIClient)
}

@_spi(STP) public class STPAnalyticsClient: NSObject, STPAnalyticsClientProtocol {
    @objc public static let sharedClient = STPAnalyticsClient()

    @objc public var productUsage: Set<String> = Set()
    private var additionalInfoSet: Set<String> = Set()
    private(set) var urlSession: URLSession = URLSession(
        configuration: StripeAPIConfiguration.sharedUrlSessionConfiguration)

    @objc public class func tokenType(fromParameters parameters: [AnyHashable: Any]) -> String? {
        let parameterKeys = parameters.keys

        // these are currently mutually exclusive, so we can just run through and find the first match
        let tokenTypes = ["account", "bank_account", "card", "pii", "cvc_update"]
        if let type = tokenTypes.first(where: { parameterKeys.contains($0) }) {
            return type
        } else {
            return parameterKeys.contains("pk_token") ? "apple_pay" : nil
        }
    }

    public func addClass<T: STPAnalyticsProtocol>(toProductUsageIfNecessary klass: T.Type) {
        objc_sync_enter(self)
        _ = productUsage.insert(klass.stp_analyticsIdentifier)
        objc_sync_exit(self)
    }

    func addAdditionalInfo(_ info: String) {
        _ = additionalInfoSet.insert(info)
    }

    public func clearAdditionalInfo() {
        additionalInfoSet.removeAll()
    }

    // MARK: - Card Scanning

    @objc class func shouldCollectAnalytics() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return NSClassFromString("XCTest") == nil
        #endif
    }

    public func additionalInfo() -> [String] {
        return additionalInfoSet.sorted()
    }

    func logPayload(_ payload: [String: Any]) {
        #if DEBUG
        NSLog("LOG ANALYTICS: \(payload)")
        #endif
        
        guard type(of: self).shouldCollectAnalytics(),
            let url = URL(string: "https://q.stripe.com")
        else {
            return
        }

        var request = URLRequest(url: url)
        request.stp_addParameters(toURL: payload)
        let task: URLSessionDataTask = urlSession.dataTask(with: request as URLRequest)
        task.resume()
    }

    /**
     Creates a payload dictionary for the given analytic that includes the event name, common payload,
     additional info, and product usage dictionary.

     - Parameter analytic: The analytic to log.
     - Parameter apiClient: The STPAPIClient instance with which this payload should be associated (i.e. publishable key). Defaults to STPAPIClient.shared
     */
    func payload(from analytic: Analytic, apiClient: STPAPIClient = .shared) -> [String: Any] {
        var payload = commonPayload(apiClient)

        payload["event"] = analytic.event.rawValue
        payload["additional_info"] = additionalInfo()
        payload["product_usage"] = productUsage.sorted()
        
        // Attach error information if this is an error analytic
        if let errorAnalytic  = analytic as? ErrorAnalytic {
            payload["error_dictionary"] = errorAnalytic.error.serializeForLogging()
        }
        
        payload.merge(analytic.params) { (_, new) in new }
        return payload
    }

    /**
     Logs an analytic with a payload dictionary that includes the event name, common payload,
     additional info, and product usage dictionary.

     - Parameter analytic: The analytic to log.
     - Parameter apiClient: The STPAPIClient instance with which this payload should be associated (i.e. publishable key). Defaults to STPAPIClient.shared
     */
    public func log(analytic: Analytic, apiClient: STPAPIClient = .shared) {
        logPayload(payload(from: analytic))
    }
}

// MARK: - Helpers
extension STPAnalyticsClient {
    public func commonPayload(_ apiClient: STPAPIClient) -> [String: Any] {
        var payload: [String: Any] = [:]
        payload["bindings_version"] = StripeAPIConfiguration.STPSDKVersion
        payload["analytics_ua"] = "analytics.stripeios-1.0"
        let version = UIDevice.current.systemVersion
        if !version.isEmpty {
            payload["os_version"] = version
        }
        if let deviceType = STPDeviceUtils.deviceType {
            payload["device_type"] = deviceType
        }
        payload["app_name"] = Bundle.stp_applicationName() ?? ""
        payload["app_version"] = Bundle.stp_applicationVersion() ?? ""
        payload["plugin_type"] = PluginDetector.shared.pluginType?.rawValue
        payload["install"] = InstallMethod.current.rawValue
        payload["publishable_key"] = apiClient.sanitizedPublishableKey ?? "unknown"
        
        return payload
    }
}
