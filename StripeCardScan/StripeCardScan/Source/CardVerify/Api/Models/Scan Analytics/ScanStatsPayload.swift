//
//  ScanStatsPayload.swift
//  StripeCardScan
//
//  Created by Jaime Park on 12/9/21.
//

import Foundation
@_spi(STP) import StripeCore

/// Parent payload structure for uploading scan stats
struct ScanStatsPayload: StripeEncodable {
    let clientSecret: String
    let payload: ScanAnalyticsPayload
    var _additionalParametersStorage: NonEncodableParameters?
}

struct ScanAnalyticsPayload: StripeEncodable {
    /// API  requirement but have no purpose
    let instanceId: String = UUID().uuidString
    /// API  requirement but have no purpose
    let scanId: String = UUID().uuidString
    let civId: String
    let payloadVersion = "2"
    let app = AppInfo()
    let device = DeviceInfo()
    let scanStats: ScanStatsTasks
    var _additionalParametersStorage: NonEncodableParameters?
}

struct ScanStatsTasks: StripeEncodable {
    let tasks: NonRepeatingTasks
    let repeatingTasks: RepeatingTasks
    var _additionalParametersStorage: NonEncodableParameters?
}

struct NonRepeatingTasks: StripeEncodable {
    let cameraPermission: [ScanAnalyticsNonRepeatingTask]
    let torchSupported: [ScanAnalyticsNonRepeatingTask]
    let scanActivity: [ScanAnalyticsNonRepeatingTask]

    init(
        cameraPermissionTask: ScanAnalyticsNonRepeatingTask,
        torchSupportedTask: ScanAnalyticsNonRepeatingTask,
        scanActivityTasks: [ScanAnalyticsNonRepeatingTask]
    ) {
        self.cameraPermission = [cameraPermissionTask]
        self.torchSupported = [torchSupportedTask]
        self.scanActivity = scanActivityTasks
    }
    var _additionalParametersStorage: NonEncodableParameters?
}

struct RepeatingTasks: StripeEncodable {
    let mainLoopImagesProcessed: ScanAnalyticsRepeatingTask
    var _additionalParametersStorage: NonEncodableParameters?
}
