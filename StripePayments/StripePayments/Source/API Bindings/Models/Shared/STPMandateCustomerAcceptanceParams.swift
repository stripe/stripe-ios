//
//  STPMandateCustomerAcceptanceParams.swift
//  StripePayments
//
//  Created by Cameron Sabol on 10/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// The type of customer acceptance information included with the Mandate.
@objc public enum STPMandateCustomerAcceptanceType: Int {
    /// A Mandate that was accepted online.
    case online
    /// A Mandate that was accepted offline.
    case offline
}

/// An object that contains details about the customer acceptance of the Mandate. - seealso: https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-mandate_data-customer_acceptance
public class STPMandateCustomerAcceptanceParams: NSObject, STPFormEncodable {

    /// The type of customer acceptance information included with the Mandate.
    @objc public var type: STPMandateCustomerAcceptanceType = .offline

    /// If this is a Mandate accepted online, this object contains details about the online acceptance.
    /// @note If `type == STPMandateCustomerAcceptanceTypeOnline`, this value must be non-nil.
    @objc public var onlineParams: STPMandateOnlineParams?

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// Initializes an empty STPMandateCustomerAcceptanceParams.
    @objc public required override init() {
        super.init()
    }

    /// Internal initializer for decoded objects
    internal init(
        type: STPMandateCustomerAcceptanceType,
        onlineParams: STPMandateOnlineParams?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.type = type
        self.onlineParams = onlineParams
        self.allResponseFields = allResponseFields
        super.init()
    }

    @objc convenience init?(
        type: STPMandateCustomerAcceptanceType,
        onlineParams: STPMandateOnlineParams?
    ) {
        guard type == .offline || onlineParams != nil else {
            return nil
        }
        self.init()
        self.type = type
        self.onlineParams = onlineParams
    }

    // MARK: - STPFormEncodable
    @objc internal var typeString: String {
        switch type {
        case .online:
            return "online"
        case .offline:
            return "offline"
        }
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: typeString)): "type",
            NSStringFromSelector(#selector(getter: onlineParams)): "online",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return "customer_acceptance"
    }
}

extension STPMandateCustomerAcceptanceParams: STPAPIResponseDecodable {
    @objc
    @_spi(STP) public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()

        guard let typeString = dict.stp_string(forKey: "type") else {
            return nil
        }

        let type: STPMandateCustomerAcceptanceType
        switch typeString {
        case "online":
            type = .online
        case "offline":
            type = .offline
        default:
            return nil
        }

        let onlineParams = STPMandateOnlineParams.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "online")
        )

        return STPMandateCustomerAcceptanceParams(
            type: type,
            onlineParams: onlineParams,
            allResponseFields: response
        ) as? Self
    }
}
