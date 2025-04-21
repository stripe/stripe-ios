//
//  AnalyticsClientV2.swift
//  StripeCore
//
//  Created by Mel Ludowise on 6/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// Dependency-injectable protocol for `AnalyticsClientV2`.
@_spi(STP) public protocol AnalyticsClientV2Protocol {
    var clientId: String { get }

    func log(eventName: String, parameters: [String: Any])
}

/// Logs analytics to `r.stripe.com`.
///
/// To log analytics to the legacy `q.stripe.com`, use `STPAnalyticsClient`.
@_spi(STP) public class AnalyticsClientV2: AnalyticsClientV2Protocol {

    static let loggerUrl = URL(string: "https://r.stripe.com/0")!

    public let clientId: String
    public let origin: String

    private(set) var urlSession: URLSession = URLSession(
        configuration: StripeAPIConfiguration.sharedUrlSessionConfiguration
    )

    /// Instantiates an AnalyticsClient capable of logging to a specific events table.
    ///
    /// - Parameters:
    ///     - clientId: The client identifier corresponding to `client_config.yaml`.
    ///     - origin: The origin corresponding to `r.stripe.com.conf`.
    public init(
        clientId: String,
        origin: String
    ) {
        self.clientId = clientId
        self.origin = origin
    }

    static let shouldCollectAnalytics: Bool = {
        #if targetEnvironment(simulator)
            return false
        #else
            return NSClassFromString("XCTest") == nil
        #endif
    }()

    var requestHeaders: [String: String] {
        return [
            "user-agent": "Stripe/v1 ios/\(StripeAPIConfiguration.STPSDKVersion)",
            "origin": origin,
        ]
    }

    /// Helper to serialize errors to a dictionary that can be included in event parameters.
    ///
    /// - Parameters:
    ///     - error: The error to serialize.
    ///     - filePath: Optionally include the filePath of the call site that threw
    ///     the error. Only the name of the file (e.g. "MyClass.swift")
    ///     will be serialized and not the full path.
    ///     - line: Optionally include the line number of the call site that threw the error.
    public static func serialize(
        error: Error,
        filePath: StaticString?,
        line: UInt?
    ) -> [String: Any] {

        var payload = error.serializeForV2Logging()

        if let filePath = filePath {
            // The full file path can contain the device name, so only include the file name
            let fileName = NSString(string: "\(filePath)").lastPathComponent
            payload["file"] = fileName
        }
        if let line = line {
            payload["line"] = line
        }

        return payload
    }

    public func log(eventName: String, parameters: [String: Any]) {
        let payload = payload(withEventName: eventName, parameters: parameters)

        #if DEBUG
        let jsonString = String(
            data: try! JSONSerialization.data(
                withJSONObject: payload,
                options: [.sortedKeys, .prettyPrinted]
            ),
            encoding: .utf8
        )!
        NSLog("LOG ANALYTICS: \(jsonString)")
        #endif

        guard AnalyticsClientV2.shouldCollectAnalytics else {
            return
        }

        var request = URLRequest(url: AnalyticsClientV2.loggerUrl)
        request.httpMethod = "POST"
        request.stp_setFormPayload(payload.jsonEncodeNestedDicts(options: .sortedKeys))
        requestHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        let task: URLSessionDataTask = urlSession.dataTask(with: request as URLRequest)
        task.resume()
    }
}

extension AnalyticsClientV2Protocol {
    public func makeCommonPayload() -> [String: Any] {
        var payload: [String: Any] = [:]

        // Required by Analytics Event Logger
        payload["client_id"] = self.clientId
        payload["event_id"] = UUID().uuidString
        payload["created"] = Date().timeIntervalSince1970

        // Common payload
        let version = UIDevice.current.systemVersion
        if !version.isEmpty {
            payload["os_version"] = version
        }
        payload["sdk_platform"] = "ios"
        payload["sdk_version"] = StripeAPIConfiguration.STPSDKVersion
        if let deviceType = STPDeviceUtils.deviceType {
            payload["device_type"] = deviceType
        }
        payload["app_name"] = Bundle.stp_applicationName() ?? ""
        payload["app_version"] = Bundle.stp_applicationVersion() ?? ""
        payload["plugin_type"] = PluginDetector.shared.pluginType?.rawValue
        payload["platform_info"] = [
            "install": InstallMethod.current.rawValue,
            "app_bundle_id": Bundle.stp_applicationBundleId() ?? "",
        ]
        if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            payload["device_id"] = deviceId
        }

        return payload
    }

    public func payload(withEventName eventName: String, parameters: [String: Any]) -> [String: Any]
    {
        var payload = makeCommonPayload()
        payload["event_name"] = eventName
        payload = payload.merging(
            parameters,
            uniquingKeysWith: { a, _ in
                return a
            }
        )
        return payload
    }
}
