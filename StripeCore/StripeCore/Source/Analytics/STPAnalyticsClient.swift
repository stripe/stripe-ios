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

/// This exists so our example/test apps can hook into when STPAnalyticsClient.sharedClient sends events.
@_spi(STP) public protocol STPAnalyticsClientDelegate: AnyObject {
    func analyticsClientDidLog(analyticsClient: STPAnalyticsClient, payload: [String: Any])
}

@_spi(STP) public class STPAnalyticsClient: NSObject, STPAnalyticsClientProtocol {
    @objc public static let sharedClient = STPAnalyticsClient()
    /// When this class logs a payload in an XCTestCase, it's added to `_testLogHistory` instead of being sent over the network.
    /// This is a hack - ideally, we inject a different analytics client in our tests. This is an escape hatch until we can make that (significant) refactor
    public var _testLogHistory: [[String: Any]] = []
    public weak var delegate: STPAnalyticsClientDelegate?

    @objc public var productUsage: Set<String> = Set()
    private var additionalInfoSet: Set<String> = Set()
    private(set) var urlSession: URLSession = URLSession(
        configuration: StripeAPIConfiguration.sharedUrlSessionConfiguration
    )
    let url = URL(string: "https://q.stripe.com")!
    private let analyticsEventTranslator = STPAnalyticsEventTranslator()
    @objc public class func tokenType(fromParameters parameters: [AnyHashable: Any]) -> String? {
        let parameterKeys = parameters.keys

        // Before SDK 23.0.0, this returned "card" for some Apple Pay payments.
        if parameterKeys.contains("pk_token") {
            return "apple_pay"
        }
        // these are currently mutually exclusive, so we can just run through and find the first match
        let tokenTypes = ["account", "bank_account", "card", "pii", "cvc_update"]
        if let type = tokenTypes.first(where: { parameterKeys.contains($0) }) {
            return type
        }
        return nil
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

    public static var isSimulatorOrTest: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return isUnitOrUITest
        #endif
    }

    static var isUnitOrUITest: Bool {
        return NSClassFromString("XCTest") != nil || ProcessInfo.processInfo.environment["UITesting"] != nil
    }

    public func additionalInfo() -> [String] {
        return additionalInfoSet.sorted()
    }

    /// Creates a payload dictionary for the given analytic that includes the event name,
    /// common payload, additional info, and product usage dictionary.
    ///
    /// - Parameters:
    ///   - analytic: The analytic to log.
    ///   - apiClient: The `STPAPIClient` instance with which this payload should be associated
    ///     (i.e. publishable key). Defaults to `STPAPIClient.shared`.
    func payload(from analytic: Analytic, apiClient: STPAPIClient = .shared) -> [String: Any] {
        var payload = commonPayload(apiClient)

        payload["event"] = analytic.event.rawValue

        payload.mergeAssertingOnOverwrites(analytic.params)
        return payload
    }

    /// Logs an analytic with a payload dictionary that includes the event name, common payload,
    /// additional info, and product usage dictionary.
    ///
    /// - Parameters
    ///   - analytic: The analytic to log.
    ///   - apiClient: The `STPAPIClient` instance with which this payload should be associated
    ///     (i.e. publishable key). Defaults to `STPAPIClient.shared`.
    public func log(analytic: Analytic, apiClient: STPAPIClient = .shared) {
        log(analytic: analytic, apiClient: apiClient, notificationCenter: .default)
    }

    func log(analytic: Analytic, apiClient: STPAPIClient = .shared, notificationCenter: NotificationCenter = .default) {
        let payload = payload(from: analytic, apiClient: apiClient)

        #if DEBUG
        NSLog("LOG ANALYTICS: \(analytic.event.rawValue) - \(analytic.params.sorted { $0.0 > $1.0 })")
        delegate?.analyticsClientDidLog(analyticsClient: self, payload: payload)
        #endif

        if let translatedEvent = analyticsEventTranslator.translate(analytic.event, payload: payload) {
            notificationCenter.post(name: translatedEvent.notificationName,
                                    object: translatedEvent.event)
        }

        // If in testing, don't log analytic, instead append payload to log history
        guard !STPAnalyticsClient.isUnitOrUITest else {
            _testLogHistory.append(payload)
            return
        }

        var request = URLRequest(url: url)
        request.stp_addParameters(toURL: payload)
        let task: URLSessionDataTask = urlSession.dataTask(with: request as URLRequest)
        task.resume()
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
        payload["network_type"] = NetworkDetector.getConnectionType()
        payload["install"] = InstallMethod.current.rawValue
        payload["publishable_key"] = apiClient.sanitizedPublishableKey ?? "unknown"
        payload["session_id"] = AnalyticsHelper.shared.sessionID
        if STPAnalyticsClient.isSimulatorOrTest {
            payload["is_development"] = true
        }
        payload["locale"] = Locale.autoupdatingCurrent.identifier
        payload["additional_info"] = additionalInfo()
        payload["product_usage"] = productUsage.sorted()
        return payload
    }
}
