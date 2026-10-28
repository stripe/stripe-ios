//
//  AnalyticsHelper.swift
//  StripeCore
//

import Foundation

@_spi(InternalOnlyAPI) public class AnalyticsHelper {
    @_spi(InternalOnlyAPI) public enum TimeMeasurement {
        case linkSignup
        case linkPopup
    }

    @_spi(InternalOnlyAPI) public static let shared = AnalyticsHelper()

    @_spi(InternalOnlyAPI) public private(set) var sessionID: String?

    private let timeProvider: () -> Date

    private var startTimes: [TimeMeasurement: Date] = [:]

    init(timeProvider: @escaping () -> Date = Date.init) {
        self.timeProvider = timeProvider
    }

    @_spi(InternalOnlyAPI) public func generateSessionID() {
        let uuid = UUID()
        // Convert the UUID to lowercase to comply with RFC 4122 and ITU-T X.667.
        sessionID = uuid.uuidString.lowercased()
    }

    func clearSessionID() {
        sessionID = nil
    }

    @_spi(InternalOnlyAPI) public func startTimeMeasurement(_ measurement: TimeMeasurement) {
        startTimes[measurement] = timeProvider()
    }

    @_spi(InternalOnlyAPI) public func getDuration(for measurement: TimeMeasurement) -> TimeInterval? {
        guard let startTime = startTimes[measurement] else {
            // Return `nil` if the time measurement hasn't started.
            return nil
        }

        let now = timeProvider()
        return now.roundedTimeIntervalSince(startTime)
    }
}

extension Date {
    @_spi(InternalOnlyAPI) public func roundedTimeIntervalSince(_ date: Date) -> TimeInterval {
        let duration = timeIntervalSince(date)

        // Round to 2 decimal places
        return round(duration * 100) / 100
    }
}
