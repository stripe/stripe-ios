//
//  AnalyticsHelper.swift
//  StripeCore
//

import Foundation

@_spi(STP) public class AnalyticsHelper {
    @_spi(STP) public enum TimeMeasurement {
        case linkSignup
        case linkPopup
    }

    @_spi(STP) public static let shared = AnalyticsHelper()

    @_spi(STP) public private(set) var sessionID: String?

    private let timeProvider: () -> Date

    private var startTimes: [TimeMeasurement: Date] = [:]

    init(timeProvider: @escaping () -> Date = Date.init) {
        self.timeProvider = timeProvider
    }

    @_spi(STP) public func generateSessionID() {
        let uuid = UUID()
        // Convert the UUID to lowercase to comply with RFC 4122 and ITU-T X.667.
        sessionID = uuid.uuidString.lowercased()
    }

    @_spi(STP) public func startTimeMeasurement(_ measurement: TimeMeasurement) {
        startTimes[measurement] = timeProvider()
    }

    @_spi(STP) public func getDuration(for measurement: TimeMeasurement) -> TimeInterval? {
        guard let startTime = startTimes[measurement] else {
            // Return `nil` if the time measurement hasn't started.
            return nil
        }

        let now = timeProvider()
        return now.roundedTimeIntervalSince(startTime)
    }
}

extension Date {
    @_spi(STP) public func roundedTimeIntervalSince(_ date: Date) -> TimeInterval {
        let duration = timeIntervalSince(date)

        // Round to 2 decimal places
        return round(duration * 100) / 100
    }
}
