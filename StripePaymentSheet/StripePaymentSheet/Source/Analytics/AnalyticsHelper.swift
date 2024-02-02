//
//  AnalyticsHelper.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 2/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

final class AnalyticsHelper {
    enum TimeMeasurement {
        case checkout
        case linkSignup
        case linkPopup
        case formShown
    }

    static let shared = AnalyticsHelper()

    private(set) var sessionID: String?

    private let timeProvider: () -> Date

    private var startTimes: [TimeMeasurement: Date] = [:]

    /// Used to ensure we only send one `mc_form_interacted` event per `mc_form_shown` to avoid spamming.
    var didSendPaymentSheetFormInteractedEventAfterFormShown: Bool = false

    init(timeProvider: @escaping () -> Date = Date.init) {
        self.timeProvider = timeProvider
    }

    func generateSessionID() {
        let uuid = UUID()
        // Convert the UUID to lowercase to comply with RFC 4122 and ITU-T X.667.
        sessionID = uuid.uuidString.lowercased()
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
