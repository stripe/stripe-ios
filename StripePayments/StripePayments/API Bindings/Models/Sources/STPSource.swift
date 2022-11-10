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
    @objc public private(set) var created: Date?
    /// The currency associated with the source.
    @objc public private(set) var currency: String?
    /// The authentication flow of the source.
    @objc public private(set) var flow: STPSourceFlow = .none
    /// Whether or not this source was created in livemode.
    @objc public private(set) var livemode = false
    /// Information about the owner of the payment instrument.
    @objc public private(set) var owner: STPSourceOwner?
    /// Information related to the receiver flow. Present if the source's flow
    /// is receiver.
    @objc public private(set) var receiver: STPSourceReceiver?
    /// Information related to the redirect flow. Present if the source's flow
    /// is redirect.
    @objc public private(set) var redirect: STPSourceRedirect?
    /// The status of the source.
    @objc public private(set) var status: STPSourceStatus = .unknown
    /// The type of the source.
    @objc public private(set) var type: STPSourceType = .unknown
    /// Whether this source should be reusable or not.
    @objc public private(set) var usage: STPSourceUsage = .unknown
    /// Information related to the verification flow. Present if the source's flow
    /// is verification.
    @objc public private(set) var verification: STPSourceVerification?
    /// Information about the source specific to its type
    @objc public private(set) var details: [AnyHashable: Any]?
    /// If this is a card source, this property provides typed access to the
    /// contents of the `details` dictionary.
    @objc public private(set) var cardDetails: STPSourceCardDetails?
    /// If this is a Klarna source, this property provides typed access to the
    /// contents of the `details` dictionary.
    @objc public private(set) var klarnaDetails: STPSourceKlarnaDetails?
    /// If this is a SEPA Debit source, this property provides typed access to the
    /// contents of the `details` dictionary.
    @objc public private(set) var sepaDebitDetails: STPSourceSEPADebitDetails?
    /// If this is a WeChat Pay source, this property provides typed access to the
    /// contents of the `details` dictionary.
    @objc public private(set) var weChatPayDetails: STPSourceWeChatPayDetails?
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
            "bancontact": NSNumber(value: STPSourceType.bancontact.rawValue),
            "card": NSNumber(value: STPSourceType.card.rawValue),
            "giropay": NSNumber(value: STPSourceType.giropay.rawValue),
            "ideal": NSNumber(value: STPSourceType.iDEAL.rawValue),
            "sepa_debit": NSNumber(value: STPSourceType.SEPADebit.rawValue),
            "sofort": NSNumber(value: STPSourceType.sofort.rawValue),
            "three_d_secure": NSNumber(value: STPSourceType.threeDSecure.rawValue),
            "alipay": NSNumber(value: STPSourceType.alipay.rawValue),
            "p24": NSNumber(value: STPSourceType.P24.rawValue),
            "eps": NSNumber(value: STPSourceType.EPS.rawValue),
            "multibanco": NSNumber(value: STPSourceType.multibanco.rawValue),
            "wechat": NSNumber(value: STPSourceType.weChatPay.rawValue),
            "klarna": NSNumber(value: STPSourceType.klarna.rawValue),
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

    // MARK: - STPSourceFlow
    class func stringToFlowMapping() -> [String: NSNumber] {
        return [
            "redirect": NSNumber(value: STPSourceFlow.redirect.rawValue),
            "receiver": NSNumber(value: STPSourceFlow.receiver.rawValue),
            "code_verification": NSNumber(value: STPSourceFlow.codeVerification.rawValue),
            "none": NSNumber(value: STPSourceFlow.none.rawValue),
        ]
    }

    @objc(flowFromString:)
    class func flow(from string: String) -> STPSourceFlow {
        let key = string.lowercased()
        let flowNumber = self.stringToFlowMapping()[key]

        if let flowNumber = flowNumber {
            return (STPSourceFlow(rawValue: flowNumber.intValue))!
        }

        return .unknown
    }

    @objc(stringFromFlow:)
    class func string(from flow: STPSourceFlow) -> String? {
        return
            (self.stringToFlowMapping() as NSDictionary).allKeys(
                for: NSNumber(value: flow.rawValue)
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
            "flow = \((STPSource.string(from: flow)) ?? "unknown")",
            "livemode = \((livemode) ? "YES" : "NO")",
            "owner = \(((owner) != nil ? "<redacted>" : nil) ?? "")",
            "receiver = \(String(describing: receiver))",
            "redirect = \(String(describing: redirect))",
            "status = \((STPSource.string(from: status)) ?? "unknown")",
            "type = \((STPSource.string(from: type)) ?? "unknown")",
            "usage = \((STPSource.string(from: usage)) ?? "unknown")",
            "verification = \(String(describing: verification))",
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
        source.created = dict.stp_date(forKey: "created")
        source.currency = dict.stp_string(forKey: "currency")
        let rawFlow = dict.stp_string(forKey: "flow")
        source.flow = self.flow(from: rawFlow ?? "")
        source.livemode = dict.stp_bool(forKey: "livemode", or: true)
        let rawOwner = dict.stp_dictionary(forKey: "owner")
        source.owner = STPSourceOwner.decodedObject(fromAPIResponse: rawOwner)
        let rawReceiver = dict.stp_dictionary(forKey: "receiver")
        source.receiver = STPSourceReceiver.decodedObject(fromAPIResponse: rawReceiver)
        let rawRedirect = dict.stp_dictionary(forKey: "redirect")
        source.redirect = STPSourceRedirect.decodedObject(fromAPIResponse: rawRedirect)
        source.status = self.status(from: rawStatus ?? "")
        source.type = self.type(from: rawType ?? "")
        let rawUsage = dict.stp_string(forKey: "usage")
        source.usage = self.usage(from: rawUsage ?? "")
        let rawVerification = dict.stp_dictionary(forKey: "verification")
        if let rawVerification = rawVerification {
            source.verification = STPSourceVerification.decodedObject(
                fromAPIResponse: rawVerification
            )
        }
        source.details = dict.stp_dictionary(forKey: rawType ?? "")
        source.allResponseFields = dict

        if source.type == .card {
            if let details1 = source.details {
                source.cardDetails = STPSourceCardDetails.decodedObject(fromAPIResponse: details1)
            }
        } else if source.type == .SEPADebit {
            source.sepaDebitDetails = STPSourceSEPADebitDetails.decodedObject(
                fromAPIResponse: source.details
            )
        } else if source.type == .weChatPay {
            source.weChatPayDetails = STPSourceWeChatPayDetails.decodedObject(
                fromAPIResponse: source.details
            )
        } else if source.type == .klarna {
            source.klarnaDetails = STPSourceKlarnaDetails.decodedObject(
                fromAPIResponse: source.details
            )
        }

        return source
    }
}
