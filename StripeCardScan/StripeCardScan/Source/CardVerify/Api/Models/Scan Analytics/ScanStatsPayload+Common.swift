//
//  ScanStatsPayload+Common.swift
//  StripeCardScan
//
//  Created by Jaime Park on 12/9/21.
//

import Foundation
@_spi(STP) import StripeCore

extension ScanAnalyticsPayload {
    init(
        configuration: ConfigurationInfo,
        payloadInfo: PayloadInfo?,
        scanStats: ScanStatsTasks
    ) {
        self.app = AppInfo(
            appPackageName: Bundle.stp_applicationName() ?? "",
            build: Bundle.buildVersion() ?? "",
            isDebugBuild: {
                #if DEBUG
                    return true
                #else
                    return false
                #endif
            }(),
            sdkVersion: StripeAPIConfiguration.STPSDKVersion
        )
        self.configuration = configuration
        self.device = DeviceInfo(
            deviceId: "Redacted",
            deviceType: {
                var systemInfo = utsname()
                uname(&systemInfo)
                var deviceType = ""
                for char in Mirror(reflecting: systemInfo.machine).children {
                    guard let charDigit = (char.value as? Int8) else {
                        break
                    }
                    if charDigit == 0 {
                        break
                    }
                    deviceType += String(UnicodeScalar(UInt8(charDigit)))
                }
                return deviceType
            }(),
            osVersion: {
                let version = ProcessInfo().operatingSystemVersion
                return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
            }(),
            platform: "iOS",
            vendorId: "Redacted"
        )
        self.payloadInfo = payloadInfo
        self.scanStats = scanStats
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
