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
@_spi(STP) public final class FraudDetectionData: Codable, Sendable {
    @MainActor
    @_spi(STP) public static var shared: FraudDetectionData =
        // Load initial value from UserDefaults
        UserDefaults.standard.fraudDetectionData ?? FraudDetectionData()
    @MainActor
    func reset() {
        Self.shared = .init()
    }
    @MainActor
    static func resetSIDIfExpired() {
        guard let sidCreationDate = Self.shared.sidCreationDate else {
            return
        }
        let thirtyMinutesAgo = Date(timeIntervalSinceNow: -SIDLifetime)
        if sidCreationDate < thirtyMinutesAgo {
            Self.shared = .init(sid: nil, muid: shared.muid, guid: shared.guid, sidCreationDate: nil)
        }
    }
    
    @_spi(STP) public let muid: String?
    @_spi(STP) public let guid: String?
    @_spi(STP) public let sid: String?

    /// The approximate time that the sid was generated from m.stripe.com
    /// Intended to be used to expire the sid after `SIDLifetime` seconds
    /// - Note: This class is a dumb container; users must set this value appropriately.
    let sidCreationDate: Date?

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

    deinit {
        // Write latest value to disk
        UserDefaults.standard.fraudDetectionData = self
    }
}

extension FraudDetectionData: Equatable {
    @_spi(STP) public static func == (lhs: FraudDetectionData, rhs: FraudDetectionData) -> Bool {
        return
            lhs.muid == rhs.muid && lhs.sid == rhs.sid && lhs.guid == rhs.guid
            && lhs.sidCreationDate == rhs.sidCreationDate
    }
}
