//
//  STPMandateOnlineParams.swift
//  Stripe
//
//  Created by Cameron Sabol on 10/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Contains details about a Mandate accepted online. - seealso: https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-mandate_data-customer_acceptance-online
public class STPMandateOnlineParams: NSObject {

    /// The IP address from which the Mandate was accepted by the customer.
    @objc public let ipAddress: String

    /// The user agent of the browser from which the Mandate was accepted by the customer.
    @objc public let userAgent: String

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    @objc internal var inferFromClient: NSNumber?

    /// Initializes an STPMandateOnlineParams.
    /// - Parameter ipAddress: The IP address from which the Mandate was accepted by the customer.
    /// - Parameter userAgent: The user agent of the browser from which the Mandate was accepted by the customer.
    /// - Returns: A new STPMandateOnlineParams instance with the specified parameters.
    @objc(initWithIPAddress:userAgent:)
    public init(ipAddress: String, userAgent: String) {
        self.ipAddress = ipAddress
        self.userAgent = userAgent
        super.init()
    }
}

extension STPMandateOnlineParams: STPFormEncodable {

    @objc internal var ipAddressField: String? {
        guard inferFromClient == nil || !(inferFromClient?.boolValue ?? false) else {
            return nil
        }
        return ipAddress
    }

    @objc internal var userAgentField: String? {
        guard inferFromClient == nil || !(inferFromClient?.boolValue ?? false) else {
            return nil
        }
        return userAgent
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter:ipAddressField)): "ip_address",
            NSStringFromSelector(#selector(getter:userAgentField)): "user_agent",
            NSStringFromSelector(#selector(getter:inferFromClient)): "infer_from_client",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return "online"
    }
}
