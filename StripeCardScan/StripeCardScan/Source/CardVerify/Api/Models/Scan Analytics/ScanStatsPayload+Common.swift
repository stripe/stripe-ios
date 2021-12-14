//
//  ScanStatsPayload+Common.swift
//  StripeCardScan
//
//  Created by Jaime Park on 12/9/21.
//

import Foundation
@_spi(STP) import StripeCore

/// Default app info used when uploading scan stats
extension ScanAnalyticsPayload {
    struct AppInfo: StripeEncodable{
        let appPackageName = Bundle.stp_applicationName() ?? ""
        let sdkVersion = Bundle.stp_applicationVersion() ?? ""
        let isDebugBuild = AppInfoUtils.getIsDebugBuild()
        let build = Bundle.buildVersion() ?? ""
        var _additionalParametersStorage: NonEncodableParameters?
    }

    /// Default device info used when uploading scan stats
    struct DeviceInfo: StripeEncodable {
        /// API  requirement but have no purpose
        let deviceId = UUID().uuidString
        let platform = "mobile"
        let osVersion = DeviceUtils.getOsVersion()
        let deviceType = DeviceUtils.getDeviceType()
        let vendorId = DeviceUtils.getVendorId()
        var _additionalParametersStorage: NonEncodableParameters?
    }
}
