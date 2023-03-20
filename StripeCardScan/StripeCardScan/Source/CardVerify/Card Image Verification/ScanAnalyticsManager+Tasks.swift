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
    case success = "success"
    case failure = "failure"
    case torchSupported = "supported"
    case torchUnsupported = "unsupported"
    case firstImageProcessed = "first_image_processed"
    case ocrPanObserved = "ocr_pan_observed"
    case cardScanned = "card_scanned"
    case enterCardManually = "enter_card_manually"
    case unknown = "unknown"
    case userCanceled = "user_canceled"
    case userMissingCard = "user_missing_card"
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

/// Task object used to track the start time and duration. Internal object used for ScanAnalyticsManager
class TrackableTask {
    var startTime: Date
    var duration: TimeInterval?
    var result: ScanAnalyticsEvent?

    init(startTime: Date = Date()) {
        self.startTime = startTime
    }

    func trackResult(_ result: ScanAnalyticsEvent, recordDuration: Bool = true) {
        self.duration = recordDuration ? Date().timeIntervalSince(startTime) : -1
        self.result = result
    }

    func toAPIModel() -> ScanAnalyticsNonRepeatingTask? {
        guard
            let result = result,
            let duration = duration
        else {
            return nil
        }

        return .init(event: result, startTime: startTime, duration: duration)
    }
}
