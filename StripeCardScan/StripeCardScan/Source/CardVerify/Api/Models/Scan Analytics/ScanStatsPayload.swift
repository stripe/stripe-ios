//
//  ScanStatsPayload.swift
//  StripeCardScan
//
//  Created by Jaime Park on 12/9/21.
//

import Foundation
@_spi(STP) import StripeCore

/// Parent payload structure for uploading scan stats
struct ScanStatsPayload: Encodable {
    let clientSecret: String
    let payload: ScanAnalyticsPayload
}

struct ScanAnalyticsPayload: Encodable {
    let app = AppInfo()
    let configuration: ConfigurationInfo
    let device = DeviceInfo()
    /// API  requirement but have no purpose
    let instanceId: String = UUID().uuidString
    let payloadVersion = "2"
    /// API  requirement but have no purpose
    let scanId: String = UUID().uuidString
    let scanStats: ScanStatsTasks
}

struct ScanStatsTasks: Encodable {
    let repeatingTasks: RepeatingTasks
    let tasks: NonRepeatingTasks
}

struct NonRepeatingTasks: Encodable {
    let cameraPermission: [ScanAnalyticsNonRepeatingTask]
    let scanActivity: [ScanAnalyticsNonRepeatingTask]
    let torchSupported: [ScanAnalyticsNonRepeatingTask]

    init(
        cameraPermissionTask: ScanAnalyticsNonRepeatingTask,
        torchSupportedTask: ScanAnalyticsNonRepeatingTask,
        scanActivityTasks: [ScanAnalyticsNonRepeatingTask]
    ) {
        self.cameraPermission = [cameraPermissionTask]
        self.torchSupported = [torchSupportedTask]
        self.scanActivity = scanActivityTasks
    }
}

struct RepeatingTasks: Encodable {
    let mainLoopImagesProcessed: ScanAnalyticsRepeatingTask
}
