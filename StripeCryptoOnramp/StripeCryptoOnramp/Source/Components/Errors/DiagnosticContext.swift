//
//  DiagnosticContext.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 6/22/26.
//

import Foundation

/// Local SDK context shared by all rich Crypto Onramp errors.
struct DiagnosticContext {

    /// SDK versions included in developer diagnostics, including Stripe iOS and any additional wrapper SDK versions.
    let sdkVersions: [SDKVersion]

    /// The SDK operation that was running when this error occurred.
    let operation: String

    /// The app identifier using the SDK, if one is available.
    let appPackageName: String?

    /// The Stripe mode associated with this error, if it can be determined.
    let mode: String?

    /// Creates local SDK diagnostic context.
    ///
    /// - Parameters:
    ///   - sdkVersions: SDK versions included in developer diagnostics, including Stripe iOS and any additional wrapper SDK versions.
    ///   - operation: The SDK operation that was running when this error occurred.
    ///   - appPackageName: The app identifier using the SDK, if one is available.
    ///   - mode: The Stripe mode associated with this error, if it can be determined.
    init(
        sdkVersions: [SDKVersion] = [],
        operation: String,
        appPackageName: String?,
        mode: String?
    ) {
        self.sdkVersions = sdkVersions.isEmpty ? [.stripeIOS] : sdkVersions
        self.operation = operation
        self.appPackageName = appPackageName
        self.mode = mode
    }
}
