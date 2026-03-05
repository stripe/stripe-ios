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
    struct AppInfo: Encodable {
        let appPackageName = Bundle.stp_applicationName() ?? ""
        let build = Bundle.buildVersion() ?? ""
        let isDebugBuild: Bool = {
            #if DEBUG
                return true
            #else
                return false
            #endif
        }()
        let sdkVersion = StripeAPIConfiguration.STPSDKVersion
    }

    /// Default device info used when uploading scan stats
    struct DeviceInfo: Encodable {
        /// API  requirement but have no purpose
        let deviceId = "Redacted"
        let deviceType: String = {
            var systemInfo = utsname()
            uname(&systemInfo)
            var deviceType = ""
            for char in Mirror(reflecting: systemInfo.machine).children {
                guard let charDigit = (char.value as? Int8) else {
                    return ""
                }

                if charDigit == 0 {
                    break
                }

                deviceType += String(UnicodeScalar(UInt8(charDigit)))
            }

            return deviceType
        }()
        let osVersion: String = {
            let version = ProcessInfo().operatingSystemVersion
            return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        }()
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
