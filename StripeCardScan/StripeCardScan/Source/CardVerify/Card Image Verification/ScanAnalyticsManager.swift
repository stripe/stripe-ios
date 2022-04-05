//
//  ScanAnalyticsManager.swift
//  StripeCardScan
//
//  Created by Jaime Park on 12/9/21.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

/// Manager used to aggregate scan analytics
class ScanAnalyticsManager {
    private let mutexQueue = DispatchQueue(label: "com.stripe.ScanAnalyticsManager.MutexQueue")
    private let configuration: CardImageVerificationSheet.Configuration
    /// The start of the scanning session
    private var startTime: Date?
    private var nonRepeatingTaskManager = NonRepeatingTasksManager()
    private var repeatingTaskManager = RepeatingTasksManager()

    init(configuration: CardImageVerificationSheet.Configuration) {
        self.configuration = configuration
    }

    func setScanSessionStartTime(time: Date) {
        mutexQueue.async {
            self.startTime = time
        }
    }

    /// Create ScanAnalyticsPayload API model
    func generateScanAnalyticsPayload(
        completion: @escaping (ScanAnalyticsPayload?
    ) -> Void) {
        mutexQueue.async { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }

            let configuration = ScanAnalyticsPayload.ConfigurationInfo(
                strictModeFrames: self.configuration.strictModeFrames.totalFrameCount
            )

            let scanStatsTasks = ScanStatsTasks(
                repeatingTasks: self.repeatingTaskManager.generateRepeatingTasks(),
                tasks: self.nonRepeatingTaskManager.generateNonRepeatingTasks()
            )

            DispatchQueue.main.async {
                completion(ScanAnalyticsPayload(
                    configuration: configuration,
                    scanStats: scanStatsTasks
                    )
                )
            }
        }
    }

    /// Keep track of most recent camera permission status
    func logCameraPermissionsTask(success: Bool) {
        /// Duration is not relevant for this task
        let task = ScanAnalyticsNonRepeatingTask(
            event: success ? .cameraPermissionSuccess : .cameraPermissionFailure,
            startTime: Date(),
            duration: 0
        )

        logCameraPermissionsTask(task)
    }

    /// Keep track of most recent torch status
    func logTorchSupportTask(supported: Bool) {
        /// Duration is not relevant for this task
        let task = ScanAnalyticsNonRepeatingTask(
            event: supported ? .torchSupported : .torchUnsupported,
            startTime: Date(),
            duration: 0
        )

        logTorchSupportTask(task)
    }

    /// Keep track of scan activities of duration from beginning of scan session
    func logScanActivityTaskFromStartTime(event: ScanAnalyticsEvent) {
        mutexQueue.async { [weak self] in
            guard let startTime = self?.startTime else {
                assertionFailure("startTime is not set")
                return
            }

            let task = ScanAnalyticsNonRepeatingTask(
                event: event,
                startTime: startTime
            )

            self?.nonRepeatingTaskManager.scanActivityTasks.append(task)
        }
    }

    /// Keep track of scan activities
    func logScanActivityTask(_ task: ScanAnalyticsNonRepeatingTask) {
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
}

private extension ScanAnalyticsManager {
    func logCameraPermissionsTask(_ task: ScanAnalyticsNonRepeatingTask) {
        mutexQueue.async { [weak self] in
            self?.nonRepeatingTaskManager.cameraPermissionTask = task
        }
    }

    func logTorchSupportTask(_ task: ScanAnalyticsNonRepeatingTask) {
        mutexQueue.async { [weak self] in
            self?.nonRepeatingTaskManager.torchSupportedTask = task
        }
    }
}
