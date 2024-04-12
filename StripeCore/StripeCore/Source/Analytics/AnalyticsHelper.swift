//
//  AnalyticsHelper.swift
//  StripeCore
//

import Foundation

@_spi(STP) public class AnalyticsHelper {
    @_spi(STP) public enum TimeMeasurement {
        case checkout
        case linkSignup
        case linkPopup
        case formShown
    }

    @_spi(STP) public static let shared = AnalyticsHelper()

    @_spi(STP) public private(set) var sessionID: String?

    private let timeProvider: () -> Date

    private var startTimes: [TimeMeasurement: Date] = [:]

    /// Used to ensure we only send one `mc_form_interacted` event per `mc_form_shown` to avoid spamming.
    @_spi(STP) public var didSendPaymentSheetFormInteractedEventAfterFormShown: Bool = false

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
        let duration = now.timeIntervalSince(startTime)

        // Round to 2 decimal places
        return round(duration * 100) / 100
    }

}
