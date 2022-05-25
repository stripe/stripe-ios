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
    struct AppInfo: Encodable{
        let appPackageName = Bundle.stp_applicationName() ?? ""
        let build = Bundle.buildVersion() ?? ""
        let isDebugBuild = AppInfoUtils.getIsDebugBuild()
        let sdkVersion = StripeAPIConfiguration.STPSDKVersion
    }

    /// Default device info used when uploading scan stats
    struct DeviceInfo: Encodable {
        /// API  requirement but have no purpose
        let deviceId = "Redacted"
        let deviceType = DeviceUtils.getDeviceType()
        let osVersion = DeviceUtils.getOsVersion()
        let platform = "iOS"
        /// API  requirement but have no purpose
        let vendorId = "Redacted"
    }

    /// Configuration values set when before running a scan flow
    struct ConfigurationInfo: Encodable {
        let strictModeFrames: Int
    }

    /// Information about the verification payload creation
    struct PayloadInfo: Encodable, Equatable {
        let imageCompressionType: String
        let imageCompressionQuality: Double
        /// Byte count of the image payload after it has been compressed and b64 encoded
        let imagePayloadSize: Int
    }
}
