//
//  STPSourceParams.swift
//  StripePayments
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a Source object.
/// - seealso: https://stripe.com/docs/api#create_source
public class STPSourceParams: NSObject, STPFormEncodable, NSCopying {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The type of the source to create. Required.

    @objc public var type: STPSourceType {
        get {
            return STPSource.type(from: rawTypeString ?? "")
        }
        set(type) {
            // If setting unknown and we're already unknown, don't want to override raw value
            if type != self.type {
                rawTypeString = STPSource.string(from: type)
            }
        }
    }
    /// The raw underlying type string sent to the server.
    /// Generally you should use `type` instead unless you have a reason not to.
    /// You can use this if you want to create a param of a type not yet supported
    /// by the current version of the SDK's `STPSourceType` enum.
    /// Setting this to a value not known by the SDK causes `type` to
    /// return `STPSourceTypeUnknown`
    @objc public var rawTypeString: String?
    /// A positive integer in the smallest currency unit representing the
    /// amount to charge the customer (e.g., @1099 for a €10.99 payment).
    /// Required for `single_use` sources.
    @objc public var amount: NSNumber?
    /// The currency associated with the source. This is the currency for which the source
    /// will be chargeable once ready.
    @objc public var currency: String?
    /// A set of key/value pairs that you can attach to a source object.
    @objc public var metadata: [AnyHashable: Any]?
    /// Information about the owner of the payment instrument. May be used or required
    /// by particular source types.
    @objc public var owner: [AnyHashable: Any]?
    /// An optional token used to create the source. When passed, token properties will
    /// override source parameters.
    @objc public var token: String?
    /// Whether this source should be reusable or not. `usage` may be "reusable" or
    /// "single_use". Some source types may or may not be reusable by construction,
    /// while other may leave the option at creation.
    @objc public var usage: STPSourceUsage

    /// Initializes an empty STPSourceParams.
    override public required init() {
        rawTypeString = ""
        usage = .unknown
        additionalAPIParameters = [:]
        super.init()
    }
}

// MARK: - Constructors
extension STPSourceParams {

    /// Creates params for a Card source.
    /// - seealso: https://stripe.com/docs/sources/cards#create-source
    /// - Parameter card:        An object containing the user's card details
    /// - Returns: an STPSourceParams object populated with the provided card details.
    @objc
    public class func cardParams(withCard card: STPCardParams) -> STPSourceParams {
        let params = self.init()
        params.type = .card
        let keyPairs = STPFormEncoder.dictionary(forObject: card)["card"] as? [AnyHashable: Any]
        var cardDict: [AnyHashable: Any] = [:]
        let cardKeys = ["number", "cvc", "exp_month", "exp_year"]
        for key in cardKeys {
            if let keyPair = keyPairs?[key] {
                cardDict[key] = keyPair
            }
        }
        params.additionalAPIParameters = [
            "card": cardDict
        ]
        var addressDict: [AnyHashable: Any] = [:]
        let addressKeyMapping = [
            "address_line1": "line1",
            "address_line2": "line2",
            "address_city": "city",
            "address_state": "state",
            "address_zip": "postal_code",
            "address_country": "country",
        ]
        for key in addressKeyMapping.keys {
            if let newKey = addressKeyMapping[key],
                let keyPair = keyPairs?[key]
            {
                addressDict[newKey] = keyPair
            }
        }
        var ownerDict: [AnyHashable: Any] = [:]
        ownerDict["address"] = addressDict
        ownerDict["name"] = card.name
        params.owner = ownerDict
        return params
    }

    @objc func usageString() -> String? {
        return STPSource.string(from: usage)
    }

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPSourceParams.self), self),
            // Basic source details
            "type = \((STPSource.string(from: type)) ?? "unknown")",
            "rawTypeString = \(rawTypeString ?? "")",
            // Additional source details (alphabetical)
            "amount = \(amount ?? 0)",
            "currency = \(currency ?? "")",
            "metadata = \(((metadata) != nil ? "<redacted>" : nil) ?? "")",
            "owner = \(((owner) != nil ? "<redacted>" : nil) ?? "")",
            "token = \(token ?? "")",
            "usage = \((STPSource.string(from: usage)) ?? "unknown")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return nil
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: rawTypeString)): "type",
            NSStringFromSelector(#selector(getter: amount)): "amount",
            NSStringFromSelector(#selector(getter: currency)): "currency",
            NSStringFromSelector(#selector(getter: metadata)): "metadata",
            NSStringFromSelector(#selector(getter: owner)): "owner",
            NSStringFromSelector(#selector(getter: token)): "token",
            NSStringFromSelector(#selector(usageString)): "usage",
        ]
    }

    // MARK: - NSCopying
    /// :nodoc:
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = Swift.type(of: self).init()
        copy.type = type
        copy.amount = amount
        copy.currency = currency
        copy.metadata = metadata
        copy.owner = owner
        copy.token = token
        copy.usage = usage
        return copy
    }
}
