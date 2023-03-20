//
//  ScanStatsPayload+Tasks.swift
//  StripeCardScan
//
//  Created by Jaime Park on 5/13/22.
//

import Foundation
/// Struct used to track a repeating event
struct ScanAnalyticsRepeatingTask: Encodable, Equatable {
    /// Repeated tasks should record how many times the tasks has been repeated
    let executions: Int
}

/// Struct used to track a non-repeating event
struct ScanAnalyticsNonRepeatingTask: Encodable, Equatable {
    let result: String
    let startedAtMs: Int
    let durationMs: Int
}
