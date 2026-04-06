//
//  ReactNativeAnalytics.swift
//  StripeCore
//

import Foundation

/// Holds metadata set by the Stripe React Native SDK for inclusion in analytics payloads.
@_spi(ReactNativeSDK) public class ReactNativeAnalytics {
    public static var isNewArchitecture: Bool?
    public static var reactNativeVersion: String?
}
