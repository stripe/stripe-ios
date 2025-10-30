//
//  STPSource.swift
//  StripePayments
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// Representation of a customer's payment instrument created with the Stripe API. - seealso: https://stripe.com/docs/api#sources
public class STPSource: NSObject, STPAPIResponseDecodable, STPSourceProtocol {

    /// You cannot directly instantiate an `STPSource`. You should only use one that
    /// has been returned from an `STPAPIClient` callback.
    override required init() {
        super.init()
    }

    /// The amount associated with the source.
    @objc public private(set) var amount: NSNumber?
    /// The client secret of the source. Used for client-side fetching of a source
    /// using a publishable key.
    @objc public private(set) var clientSecret: String?
    /// When the source was created.
    @objc public private(set) var created: Date = Date(timeIntervalSince1970: TimeInterval(0))
    /// The currency associated with the source.
    @objc public private(set) var currency: String?
    /// Whether or not this source was created in livemode.
    @objc public private(set) var livemode = false
    /// The status of the source.
    @objc public private(set) var status: STPSourceStatus = .unknown
    /// The type of the source.
    @objc public private(set) var type: STPSourceType = .unknown
    /// Whether this source should be reusable or not.
    @objc public private(set) var usage: STPSourceUsage = .unknown
    /// Information about the source specific to its type
    @objc public private(set) var details: [AnyHashable: Any]?
    /// If this is a card source, this property provides typed access to the
    /// contents of the `details` dictionary.
    @objc public private(set) var cardDetails: STPSourceCardDetails?
    // MARK: - Deprecated

    /// A set of key/value pairs associated with the source object.
    /// @deprecated Metadata is no longer returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead.
    /// - seealso: https://stripe.com/docs/api#metadata
    @available(
        *,
        deprecated,
        message:
            "Metadata is no longer returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead."
    )
    @objc public private(set) var metadata: [String: String]?
    @objc public var stripeID = ""
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - STPSourceType
    class func stringToTypeMapping() -> [String: NSNumber] {
        return [
            "card": NSNumber(value: STPSourceType.card.rawValue),
        ]
    }

    @objc(typeFromString:)
    class func type(from string: String) -> STPSourceType {
        let key = string.lowercased()
        let typeNumber = self.stringToTypeMapping()[key]

        if let typeNumber = typeNumber {
            return (STPSourceType(rawValue: typeNumber.intValue))!
        }

        return .unknown
    }

    @objc(stringFromType:)
    class func string(from type: STPSourceType) -> String? {
        return
            (self.stringToTypeMapping() as NSDictionary).allKeys(
                for: NSNumber(value: type.rawValue)
            )
            .first as? String
    }

    // MARK: - STPSourceStatus
    class func stringToStatusMapping() -> [String: NSNumber] {
        return [
            "pending": NSNumber(value: STPSourceStatus.pending.rawValue),
            "chargeable": NSNumber(value: STPSourceStatus.chargeable.rawValue),
            "consumed": NSNumber(value: STPSourceStatus.consumed.rawValue),
            "canceled": NSNumber(value: STPSourceStatus.canceled.rawValue),
            "failed": NSNumber(value: STPSourceStatus.failed.rawValue),
        ]
    }

    @objc(statusFromString:)
    class func status(from string: String) -> STPSourceStatus {
        let key = string.lowercased()
        let statusNumber = self.stringToStatusMapping()[key]

        if let statusNumber = statusNumber {
            return (STPSourceStatus(rawValue: statusNumber.intValue))!
        }

        return .unknown
    }

    @objc(stringFromStatus:)
    class func string(from status: STPSourceStatus) -> String? {
        return
            (self.stringToStatusMapping() as NSDictionary).allKeys(
                for: NSNumber(value: status.rawValue)
            )
            .first as? String
    }

    // MARK: - STPSourceUsage
    class func stringToUsageMapping() -> [String: NSNumber] {
        return [
            "reusable": NSNumber(value: STPSourceUsage.reusable.rawValue),
            "single_use": NSNumber(value: STPSourceUsage.singleUse.rawValue),
        ]
    }

    @objc(usageFromString:)
    class func usage(from string: String) -> STPSourceUsage {
        let key = string.lowercased()
        let usageNumber = self.stringToUsageMapping()[key]

        if let usageNumber = usageNumber {
            return (STPSourceUsage(rawValue: usageNumber.intValue))!
        }

        return .unknown
    }

    @objc(stringFromUsage:)
    class func string(from usage: STPSourceUsage) -> String? {
        return
            (self.stringToUsageMapping() as NSDictionary).allKeys(
                for: NSNumber(value: usage.rawValue)
            )
            .first as? String
    }

    // MARK: - Equality
    /// :nodoc:
    @objc
    public override func isEqual(_ object: Any?) -> Bool {
        return isEqual(to: object as? STPSource)
    }

    /// :nodoc:
    @objc public override var hash: Int {
        return stripeID.hash
    }

    func isEqual(to source: STPSource?) -> Bool {
        if self === source {
            return true
        }

        guard let source = source else {
            return false
        }

        return stripeID == source.stripeID
    }

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPSource.self), self),
            // Identifier
            "stripeID = \(stripeID)",
            // Source details (alphabetical)
            "amount = \(amount ?? 0)",
            "clientSecret = \(((clientSecret) != nil ? "<redacted>" : nil) ?? "")",
            "created = \(String(describing: created))",
            "currency = \(currency ?? "")",
            "livemode = \((livemode) ? "YES" : "NO")",
            "status = \((STPSource.string(from: status)) ?? "unknown")",
            "type = \((STPSource.string(from: type)) ?? "unknown")",
            "usage = \((STPSource.string(from: usage)) ?? "unknown")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    @objc func stripeObject() -> String {
        return "source"
    }

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()

        // required fields
        let stripeId = dict.stp_string(forKey: "id")
        let rawStatus = dict.stp_string(forKey: "status")
        let rawType = dict.stp_string(forKey: "type")
        if stripeId == nil || rawStatus == nil || rawType == nil || dict["livemode"] == nil {
            return nil
        }

        let source = self.init()
        source.stripeID = stripeId ?? ""
        source.amount = dict.stp_number(forKey: "amount")
        source.clientSecret = dict.stp_string(forKey: "client_secret")
        source.created = dict.stp_date(forKey: "created") ?? Date(timeIntervalSince1970: TimeInterval(0))
        source.currency = dict.stp_string(forKey: "currency")
        source.livemode = dict.stp_bool(forKey: "livemode", or: true)
        source.status = self.status(from: rawStatus ?? "")
        source.type = self.type(from: rawType ?? "")
        let rawUsage = dict.stp_string(forKey: "usage")
        source.usage = self.usage(from: rawUsage ?? "")
        source.details = dict.stp_dictionary(forKey: rawType ?? "")
        source.allResponseFields = dict

        if source.type == .card {
            if let details1 = source.details {
                source.cardDetails = STPSourceCardDetails.decodedObject(fromAPIResponse: details1)
            }
        }

        return source
    }
}
