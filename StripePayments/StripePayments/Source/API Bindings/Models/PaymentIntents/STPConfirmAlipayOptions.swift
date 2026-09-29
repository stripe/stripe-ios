//
//  STPConfirmAlipayOptions.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 5/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// Alipay options to pass to `STPConfirmPaymentMethodOptions`.
public class STPConfirmAlipayOptions: NSObject {

    /// Three-letter ISO currency code in lowercase. Required when confirming a SetupIntent.
    @objc public var currency: String?

    /// Indicates that you intend to make future payments with this payment method.
    /// Alipay only supports `STPPaymentIntentSetupFutureUsage.offSession`.
    @objc public var setupFutureUsage: STPPaymentIntentSetupFutureUsage = .none

    /// The app bundle ID.
    /// @note This is automatically populated by the SDK.
    @objc public var appBundleID: String {
        return Bundle.main.bundleIdentifier ?? ""
    }

    /// The app version.
    /// @note This is automatically populated by the SDK.
    @objc public var appVersionKey: String {
        return Bundle.stp_applicationVersion() ?? "1.0.0"  // Should only be nil for tests
    }

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(type(of: self)), self),
            "currency = \(String(describing: currency))",
            "appBundleID = \(appBundleID)",
            "appVersionKey = \(appVersionKey)",
            "setupFutureUsage = \(setupFutureUsage)",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

}

// MARK: - STPFormEncodable
extension STPConfirmAlipayOptions: STPFormEncodable {
    @objc internal var setupFutureUsageRawString: String? {
        return setupFutureUsage.stringValue
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: currency)): "currency",
            NSStringFromSelector(#selector(getter: appBundleID)): "app_bundle_id",
            NSStringFromSelector(#selector(getter: appVersionKey)): "app_version_key",
            NSStringFromSelector(#selector(getter: setupFutureUsageRawString)): "setup_future_usage",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return "alipay"
    }
}
