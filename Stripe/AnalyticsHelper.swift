//
//  AnalyticsHelper.swift
//  StripeiOS
//
//  Created by Ramon Torres on 2/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

final class AnalyticsHelper {
    enum TimeMeasurement {
        case checkout
        case linkSignup
    }

    static let shared = AnalyticsHelper()

    private let timeProvider: () -> Date

    private var startTimes: [TimeMeasurement: Date] = [:]

    init(timeProvider: @escaping () -> Date = Date.init) {
        self.timeProvider = timeProvider
    }

    func startTimeMeasurement(_ measurement: TimeMeasurement) {
        startTimes[measurement] = timeProvider()
    }

    func getDuration(for measurement: TimeMeasurement) -> TimeInterval? {
        guard let startTime = startTimes[measurement] else {
            // Return `nil` if the time measurement hasn't started.
            return nil
        }

        let now = timeProvider()
        let duration = now.timeIntervalSince(startTime)

        // Round to 2 decimal places
        return round(duration * 100) / 100
    }

}
