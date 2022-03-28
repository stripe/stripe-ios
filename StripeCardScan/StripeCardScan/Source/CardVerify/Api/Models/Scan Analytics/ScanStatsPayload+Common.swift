//
//  ScanStatsPayload+Common.swift
//  StripeCardScan
//
//  Created by Jaime Park on 12/9/21.
//

import Foundation
@_spi(STP) import StripeCore

extension ScanAnalyticsPayload {
    /// Default app info used when uploading scan stats
    struct AppInfo: StripeEncodable{
        let appPackageName = Bundle.stp_applicationName() ?? ""
        let build = Bundle.buildVersion() ?? ""
        let isDebugBuild = AppInfoUtils.getIsDebugBuild()
        let sdkVersion = StripeAPIConfiguration.STPSDKVersion
        var _additionalParametersStorage: NonEncodableParameters?
    }

    /// Default device info used when uploading scan stats
    struct DeviceInfo: StripeEncodable {
        /// API  requirement but have no purpose
        let deviceId = "Redacted"
        let deviceType = DeviceUtils.getDeviceType()
        let osVersion = DeviceUtils.getOsVersion()
        let platform = "iOS"
        /// API  requirement but have no purpose
        let vendorId = "Redacted"
        var _additionalParametersStorage: NonEncodableParameters?
    }

    /// Configuration values set when before running a scan flow
    struct ConfigurationInfo: StripeEncodable {
        let strictModeFrames: Int
        var _additionalParametersStorage: NonEncodableParameters?
    }
}
