//
//  SentryContext.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-10-22.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

struct SentryContext: Encodable {
    let app: SentryAppContext
    let os: SentryOsContext
    let device: SentryDeviceContext

    static let shared: SentryContext = {
        let app = SentryAppContext(
            appIdentifier: Bundle.stp_applicationBundleId() ?? "",
            appName: Bundle.stp_applicationName() ?? "",
            appVersion: Bundle.stp_applicationVersion() ?? ""
        )
        let os = SentryOsContext(
            name: "iOS",
            version: UIDevice.current.systemVersion,
            type: InstallMethod.current.rawValue
        )
        let device = SentryDeviceContext(
            modelId: UIDevice.current.identifierForVendor?.uuidString ?? "",
            model: UIDevice.current.model,
            manufacturer: "Apple",
            type: STPDeviceUtils.deviceType ?? ""
        )

        return SentryContext(app: app, os: os, device: device)
    }()
}

struct SentryAppContext: Encodable {
    let appIdentifier: String
    let appName: String
    let appVersion: String
}

struct SentryOsContext: Encodable {
    let name: String
    let version: String
    let type: String
}

struct SentryDeviceContext: Encodable {
    let modelId: String
    let model: String
    let manufacturer: String
    let type: String
}
