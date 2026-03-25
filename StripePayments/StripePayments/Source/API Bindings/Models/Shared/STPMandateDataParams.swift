//
//  STPMandateDataParams.swift
//  StripePayments
//
//  Created by Cameron Sabol on 10/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// This object contains details about the Mandate to create. - seealso: https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-mandate_data
public class STPMandateDataParams: NSObject {

    /// Details about the customer acceptance of the Mandate.
    @objc public let customerAcceptance: STPMandateCustomerAcceptanceParams

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// Initializes an STPMandateDataParams from an STPMandateCustomerAcceptanceParams.
    @objc public init(
        customerAcceptance: STPMandateCustomerAcceptanceParams
    ) {
        self.customerAcceptance = customerAcceptance
        super.init()
    }

    /// Internal initializer for decoded objects
    internal init(
        customerAcceptance: STPMandateCustomerAcceptanceParams,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.customerAcceptance = customerAcceptance
        self.allResponseFields = allResponseFields
        super.init()
    }

    /// Create mandate data by inferring its values from the client
    @_spi(STP) public static func makeWithInferredValues() -> STPMandateDataParams {
        let onlineParams = STPMandateOnlineParams(ipAddress: "", userAgent: "")
        onlineParams.inferFromClient = NSNumber(value: true)

        let customerAcceptanceParams = STPMandateCustomerAcceptanceParams()
        customerAcceptanceParams.type = .online
        customerAcceptanceParams.onlineParams = onlineParams

        return STPMandateDataParams(customerAcceptance: customerAcceptanceParams)
    }
}

extension STPMandateDataParams: STPFormEncodable {
    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: customerAcceptance)): "customer_acceptance",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return "mandate_data"
    }
}

extension STPMandateDataParams: STPAPIResponseDecodable {
    @objc
    @_spi(STP) public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()

        guard let customerAcceptance = STPMandateCustomerAcceptanceParams.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "customer_acceptance")
        ) else {
            return nil
        }

        return STPMandateDataParams(
            customerAcceptance: customerAcceptance,
            allResponseFields: response
        ) as? Self
    }
}
