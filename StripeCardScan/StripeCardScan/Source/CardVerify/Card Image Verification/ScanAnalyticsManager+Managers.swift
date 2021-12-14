//
//  ScanAnalyticsManager+Managers.swift
//  StripeCardScan
//
//  Created by Jaime Park on 12/13/21.
//

import Foundation

/// Manager used to aggregate all non-repeating tasks
struct NonRepeatingTasksManager {
    /// Default to failure with negative values
    var cameraPermissionTask: ScanAnalyticsNonRepeatingTask = .init(result: ScanAnalyticsEvent.cameraPermissionFailure.rawValue, startedAtMs: -1, durationMs: -1)
    var torchSupportedTask: ScanAnalyticsNonRepeatingTask = .init(result: ScanAnalyticsEvent.torchUnsupported.rawValue, startedAtMs: -1, durationMs: -1)
    var scanActivityTasks: [ScanAnalyticsNonRepeatingTask] = []

    /// Create API model
    func generateNonRepeatingTasks() -> NonRepeatingTasks {
        return .init(
            cameraPermissionTask: cameraPermissionTask,
            torchSupportedTask: torchSupportedTask,
            scanActivityTasks: scanActivityTasks
        )
    }
}

/// Manager used to aggregate all repeating tasks
struct RepeatingTasksManager {
    /// Default to negative number frames processed
    var mainLoopImagesProcessed: ScanAnalyticsRepeatingTask = .init(executions: -1)

    /// Create API model
    func generateRepeatingTasks() -> RepeatingTasks {
        return .init(mainLoopImagesProcessed: mainLoopImagesProcessed)
    }
}
