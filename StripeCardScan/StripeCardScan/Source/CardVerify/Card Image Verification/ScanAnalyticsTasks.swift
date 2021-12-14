//
//  ScanAnalyticsTasks.swift
//  StripeCardScan
//
//  Created by Jaime Park on 12/9/21.
//

import Foundation

/// Events to be logged during a scanning session
enum ScanAnalyticsEvent: String {
    /// Non-repeating tasks
    case cameraPermissionSuccess = "success"
    case cameraPermissionFailure = "failure"
    case torchSupported = "supported"
    case torchUnsupported = "unsupported"
    case firstImageProcessed = "first_image_processed"
    case ocrPanObserved = "ocr_pan_observed"
    case cardScanned = "card_scanned"
    case enterCardManually = "enter_card_manually"
    case userCanceled = "user_canceled"
    case userMissingCard = "user_missing_card"
}

/// Struct used to track a repeating event
struct ScanAnalyticsRepeatingTask: Encodable {
    /// Repeated tasks should record how many times the tasks has been repeated
    let executions: Int
}

/// Struct used to track a non-repeating event
struct ScanAnalyticsNonRepeatingTask: Encodable {
    let result: String
    let startedAtMs: Int
    let durationMs: Int
}

extension ScanAnalyticsNonRepeatingTask {
    /// Many events will have a fixed start time. The duration will be measured from when the task is created.
    init(
        event: ScanAnalyticsEvent,
        startTime: Date,
        endTime: Date = Date()
    ) {
        self.init(
            event: event,
            startTime: startTime,
            duration: endTime.timeIntervalSince(startTime)
        )
    }

    init(
        event: ScanAnalyticsEvent,
        startTime: Date,
        duration: TimeInterval
    ) {
        self.init(
            result: event.rawValue,
            startedAtMs: startTime.millisecondsSince1970,
            durationMs: duration.milliseconds
        )
    }
}
