//
//  STPAnalyticsClient.swift
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

protocol STPAnalyticsProtocol {
    static var stp_analyticsIdentifier: String { get }
}

protocol STPAnalyticsClientProtocol {
    func addClass<T: STPAnalyticsProtocol>(toProductUsageIfNecessary klass: T.Type)
    func log(analytic: Analytic)
}

class STPAnalyticsClient: NSObject, STPAnalyticsClientProtocol {
    @objc static let sharedClient = STPAnalyticsClient()

    @objc internal var productUsage: Set<String> = Set()
    private var additionalInfoSet: Set<String> = Set()
    private(set) var urlSession: URLSession = URLSession(
        configuration: STPAPIClient.sharedUrlSessionConfiguration)

    @objc class func tokenType(fromParameters parameters: [AnyHashable: Any]) -> String? {
        let parameterKeys = parameters.keys

        // these are currently mutually exclusive, so we can just run through and find the first match
        let tokenTypes = ["account", "bank_account", "card", "pii", "cvc_update"]
        if let type = tokenTypes.first(where: { parameterKeys.contains($0) }) {
            return type
        } else {
            return parameterKeys.contains("pk_token") ? "apple_pay" : nil
        }
    }

    func addClass<T: STPAnalyticsProtocol>(toProductUsageIfNecessary klass: T.Type) {
        objc_sync_enter(self)
        _ = productUsage.insert(klass.stp_analyticsIdentifier)
        objc_sync_exit(self)
    }

    func addAdditionalInfo(_ info: String) {
        _ = additionalInfoSet.insert(info)
    }

    func clearAdditionalInfo() {
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

    func additionalInfo() -> [String] {
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

        let request: NSMutableURLRequest = NSMutableURLRequest(url: url)

        request.stp_addParameters(toURL: payload)
        let task: URLSessionDataTask = urlSession.dataTask(with: request as URLRequest)
        task.resume()
    }

    /**
     Creates a payload dictionary for the given analytic that includes the event name, common payload,
     additional info, and product usage dictionary.

     - Parameter analytic: The analytic to log.
     */
    func payload(from analytic: Analytic) -> [String: Any] {
        var payload = type(of: self).commonPayload()

        payload["event"] = analytic.event.rawValue
        payload["additional_info"] = additionalInfo()
        payload["product_usage"] = productUsage.sorted()

        payload.merge(analytic.params) { (_, new) in new }
        return payload
    }

    /**
     Logs an analytic with a payload dictionary that includes the event name, common payload,
     additional info, and product usage dictionary.

     - Parameter analytic: The analytic to log.
     */
    func log(analytic: Analytic) {
        logPayload(payload(from: analytic))
    }
}

// MARK: - Helpers
extension STPAnalyticsClient {
    class func commonPayload() -> [String: Any] {
        var payload: [String: Any] = [:]
        payload["bindings_version"] = STPAPIClient.STPSDKVersion
        payload["analytics_ua"] = "analytics.stripeios-1.0"
        let version = UIDevice.current.systemVersion
        if !version.isEmpty {
            payload["os_version"] = version
        }
        var systemInfo: utsname = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let deviceType = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        if !deviceType.isEmpty {
            payload["device_type"] = deviceType
        }
        payload["app_name"] = Bundle.stp_applicationName() ?? ""
        payload["app_version"] = Bundle.stp_applicationVersion() ?? ""
        payload["publishable_key"] = STPAPIClient.shared.publishableKey ?? "unknown"
        
        return payload
    }

    class func serializeError(_ error: NSError) -> [String: Any] {
        // TODO(mludowise|MOBILESDK-193): Find a better solution than logging `userInfo`
        return [
            "domain": error.domain,
            "code": error.code,
            "user_info": error.userInfo,
        ]
    }
}
