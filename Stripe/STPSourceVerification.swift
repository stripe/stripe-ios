//
//  STPSourceVerification.swift
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

/// Verification status types for a Source.
@objc
public enum STPSourceVerificationStatus: Int {
    /// The verification is pending.
    case pending
    /// The verification has succeeeded.
    case succeeded
    /// The verification has failed.
    case failed
    /// The state of the verification is unknown.
    case unknown
}

/// Information related to a source's verification flow.
public class STPSourceVerification: NSObject, STPAPIResponseDecodable {
    /// The number of attempts remaining to authenticate the source object with a
    /// verification code.
    @objc public private(set) var attemptsRemaining: NSNumber?
    /// The status of the verification.
    @objc public private(set) var status: STPSourceVerificationStatus = .unknown
    @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - STPSourceVerificationStatus
    class func stringToStatusMapping() -> [String: NSNumber] {
        return [
            "pending": NSNumber(value: STPSourceVerificationStatus.pending.rawValue),
            "succeeded": NSNumber(value: STPSourceVerificationStatus.succeeded.rawValue),
            "failed": NSNumber(value: STPSourceVerificationStatus.failed.rawValue),
        ]
    }

    @objc(statusFromString:)
    class func status(from string: String) -> STPSourceVerificationStatus {
        let key = string.lowercased()
        let statusNumber = self.stringToStatusMapping()[key]

        if let statusNumber = statusNumber {
            return (STPSourceVerificationStatus(rawValue: statusNumber.intValue))!
        }

        return .unknown
    }

    @objc(stringFromStatus:)
    class func string(from status: STPSourceVerificationStatus) -> String? {
        return
            (self.stringToStatusMapping() as NSDictionary).allKeys(
                for: NSNumber(value: status.rawValue)
            )
            .first as? String
    }

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPSourceVerification.self), self),
            // Details (alphabetical)
            "attemptsRemaining = \(attemptsRemaining ?? 0)",
            "status = \((STPSourceVerification.string(from: status)) ?? "unknown")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    override required init() {
        super.init()
    }

    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

        // required fields
        let rawStatus = dict.stp_string(forKey: "status")
        if rawStatus == nil {
            return nil
        }

        let verification = self.init()
        verification.attemptsRemaining = dict.stp_number(forKey: "attempts_remaining")
        verification.status = self.status(from: rawStatus ?? "")
        verification.allResponseFields = response
        return verification
    }
}
