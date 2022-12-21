//
//  FraudDetectionData.swift
//  StripeCore
//
//  Created by Yuki Tokuhiro on 5/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

private let SIDLifetime: TimeInterval = 30 * 60  // 30 minutes

/// Contains encoded values returned from m.stripe.com.
///
/// - Note: See `STPTelemetryClient`.
/// - Note: See `StripeAPI.advancedFraudSignalsEnabled`.
@_spi(STP) public final class FraudDetectionData: Codable {
    @_spi(STP) public static let shared: FraudDetectionData =
        // Load initial value from UserDefaults
        UserDefaults.standard.fraudDetectionData ?? FraudDetectionData()

    @_spi(STP) public var muid: String?
    @_spi(STP) public var guid: String?
    @_spi(STP) public var sid: String?

    /// The approximate time that the sid was generated from m.stripe.com
    /// Intended to be used to expire the sid after `SIDLifetime` seconds
    /// - Note: This class is a dumb container; users must set this value appropriately.
    var sidCreationDate: Date?

    init(
        sid: String? = nil,
        muid: String? = nil,
        guid: String? = nil,
        sidCreationDate: Date? = nil
    ) {
        self.sid = sid
        self.muid = muid
        self.guid = guid
        self.sidCreationDate = sidCreationDate
    }

    func resetSIDIfExpired() {
        guard let sidCreationDate = sidCreationDate else {
            return
        }
        let thirtyMinutesAgo = Date(timeIntervalSinceNow: -SIDLifetime)
        if sidCreationDate < thirtyMinutesAgo {
            sid = nil
        }
    }

    deinit {
        // Write latest value to disk
        UserDefaults.standard.fraudDetectionData = self
    }

    func reset() {
        self.sid = nil
        self.muid = nil
        self.guid = nil
        self.sidCreationDate = nil
    }
}

extension FraudDetectionData: Equatable {
    @_spi(STP) public static func == (lhs: FraudDetectionData, rhs: FraudDetectionData) -> Bool {
        return
            lhs.muid == rhs.muid && lhs.sid == rhs.sid && lhs.guid == rhs.guid
            && lhs.sidCreationDate == rhs.sidCreationDate
    }
}
