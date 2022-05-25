//
//  ScanAnalyticsManager.swift
//  StripeCardScan
//
//  Created by Jaime Park on 12/9/21.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

typealias PayloadInfo =  ScanAnalyticsPayload.PayloadInfo

/// Manager used to aggregate scan analytics
class ScanAnalyticsManager {
    /// Shared scan analytics manager singleton
    static private(set) var shared = ScanAnalyticsManager()

    private let mutexQueue = DispatchQueue(label: "com.stripe.ScanAnalyticsManager.MutexQueue")
    /// The start of the scanning session
    private var startTime: Date?
    private var nonRepeatingTaskManager = NonRepeatingTasksManager()
    private var payloadInfo: PayloadInfo?
    private var repeatingTaskManager = RepeatingTasksManager()

    init() {}

    func setScanSessionStartTime(time: Date) {
        mutexQueue.async {
            self.startTime = time
        }
    }

    /// Create ScanAnalyticsPayload API model
    func generateScanAnalyticsPayload(
        with configuration: CardImageVerificationSheet.Configuration,
        completion: @escaping (ScanAnalyticsPayload?
    ) -> Void) {
        mutexQueue.async { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }

            let configuration = ScanAnalyticsPayload.ConfigurationInfo(
                strictModeFrames: configuration.strictModeFrames.totalFrameCount
            )

            let scanStatsTasks = ScanStatsTasks(
                repeatingTasks: self.repeatingTaskManager.generateRepeatingTasks(),
                tasks: self.nonRepeatingTaskManager.generateNonRepeatingTasks()
            )

            DispatchQueue.main.async {
                completion(ScanAnalyticsPayload(
                    configuration: configuration,
                    payloadInfo: self.payloadInfo,
                    scanStats: scanStatsTasks
                    )
                )
            }
        }
    }

    /// Keep track of most recent camera permission status
    func logCameraPermissionsTask(success: Bool) {
        mutexQueue.async { [weak self] in
            /// Duration is not relevant for this task
            let task = TrackableTask()
            task.trackResult(success ? .success : .failure, recordDuration: false)
            self?.nonRepeatingTaskManager.cameraPermissionTask = task
        }
    }

    /// Keep track of most recent torch status
    func logTorchSupportTask(supported: Bool) {
        mutexQueue.async { [weak self] in
            /// Duration is not relevant for this task
            let task = TrackableTask()
            task.trackResult(supported ? .torchSupported : .torchUnsupported, recordDuration: false)
            self?.nonRepeatingTaskManager.torchSupportedTask = task
        }
    }

    /// Keep track of scan activities of duration from beginning of scan session
    func logScanActivityTaskFromStartTime(event: ScanAnalyticsEvent) {
        mutexQueue.async { [weak self] in
            guard let startTime = self?.startTime else {
                assertionFailure("startTime is not set")
                return
            }

            let task = TrackableTask(startTime: startTime)
            task.trackResult(event)
            self?.logScanActivityTask(task: task)
        }
    }

    /// Keep track of scan activities and their start time, duration is not as important
    func logScanActivityTask(event: ScanAnalyticsEvent) {
        let task = TrackableTask(startTime: Date())
        task.trackResult(event, recordDuration: false)
        self.logScanActivityTask(task: task)
    }

    /// Keep track of the start time and duration of a scan event
    func logScanActivityTask(task: TrackableTask) {
        mutexQueue.async { [weak self] in
            self?.nonRepeatingTaskManager.scanActivityTasks.append(task)
        }
    }

    /// Keep track of how many frames were processed this session
    func logMainLoopImageProcessedRepeatingTask(_ task: ScanAnalyticsRepeatingTask) {
        mutexQueue.async { [weak self] in
            self?.repeatingTaskManager.mainLoopImagesProcessed = task
        }
    }

    /// Keep track of the payload data used for the verification payload creation
    func logPayloadInfo(with payloadInfo: PayloadInfo) {
        mutexQueue.async { [weak self] in
            self?.payloadInfo = payloadInfo
        }
    }

    /// Keep  track of the start time and duration of the completion loop
    func trackCompletionLoopDuration(task: TrackableTask) {
        mutexQueue.async { [weak self] in
            self?.nonRepeatingTaskManager.completionLoopDuration = task
        }
    }

    /// Keep  track of the start time and duration of the image compression
    func trackImageCompressionDuration(task: TrackableTask) {
        mutexQueue.async { [weak self] in
            self?.nonRepeatingTaskManager.imageCompressionDuration = task
        }
    }

    /// Keep  track of the start time and duration of the main loop
    func trackMainLoopDuration(task: TrackableTask) {
        mutexQueue.async { [weak self] in
            self?.nonRepeatingTaskManager.mainLoopDuration = task
        }
    }

    /// Clear the scan analytics manager instance
    func reset() {
        mutexQueue.async { [weak self] in
            self?.startTime = nil
            self?.nonRepeatingTaskManager = NonRepeatingTasksManager()
            self?.payloadInfo = nil
            self?.repeatingTaskManager = RepeatingTasksManager()
        }
    }
}
