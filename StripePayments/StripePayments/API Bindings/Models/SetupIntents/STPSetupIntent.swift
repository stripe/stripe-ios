//
//  STPSetupIntent.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// A SetupIntent guides you through the process of setting up a customer's payment credentials for future payments.
/// - seealso: https://stripe.com/docs/api/setup_intents
public class STPSetupIntent: NSObject, STPAPIResponseDecodable {
    /// The Stripe ID of the SetupIntent.
    @objc public let stripeID: String
    /// The client secret of this SetupIntent. Used for client-side retrieval using a publishable key.
    @objc public let clientSecret: String
    /// Time at which the object was created.
    @objc public let created: Date
    /// ID of the Customer this SetupIntent belongs to, if one exists.
    @objc public let customerID: String?
    /// An arbitrary string attached to the object. Often useful for displaying to users.
    @objc public let stripeDescription: String?
    /// Has the value `YES` if the object exists in live mode or the value `NO` if the object exists in test mode.
    @objc public let livemode: Bool
    /// If present, this property tells you what actions you need to take in order for your customer to set up this payment method.
    @objc public let nextAction: STPIntentAction?
    /// ID of the payment method used with this SetupIntent.
    @objc public let paymentMethodID: String?
    /// The optionally expanded PaymentMethod used in this SetupIntent.
    @objc public let paymentMethod: STPPaymentMethod?
    /// The list of payment method types (e.g. `[STPPaymentMethodType.card]`) that this SetupIntent is allowed to set up.
    @objc public let paymentMethodTypes: [NSNumber]
    /// Status of this SetupIntent.
    @objc public let status: STPSetupIntentStatus
    /// Indicates how the payment method is intended to be used in the future.
    @objc public let usage: STPSetupIntentUsage
    /// The setup error encountered in the previous SetupIntent confirmation.
    @objc public let lastSetupError: STPSetupIntentLastSetupError?
    /// The ordered payment method preference for this SetupIntent
    @_spi(STP) public let orderedPaymentMethodTypes: [STPPaymentMethodType]
    /// A list of payment method types that are not activated in live mode, but activated in test mode
    @_spi(STP) public let unactivatedPaymentMethodTypes: [STPPaymentMethodType]
    /// Payment-method-specific configuration for this SetupIntent.
    @_spi(STP) public let paymentMethodOptions: STPPaymentMethodOptions?
    /// Link-specific settings for this SetupIntent.
    @_spi(STP) public let linkSettings: LinkSettings?
    /// Country code of the user.
    @_spi(STP) public let countryCode: String?
    // MARK: - Deprecated

    /// Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    /// @deprecated Metadata is not  returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead.
    /// - seealso: https://stripe.com/docs/api#metadata
    @available(
        *,
        deprecated,
        message:
            "Metadata is not returned to clients using publishable keys. Retrieve them on your server using your secret key instead."
    )
    @objc public private(set) var metadata: [String: String]?
    @objc public let allResponseFields: [AnyHashable: Any]

    required init(
        stripeID: String,
        clientSecret: String,
        created: Date,
        countryCode: String?,
        customerID: String?,
        stripeDescription: String?,
        linkSettings: LinkSettings?,
        livemode: Bool,
        nextAction: STPIntentAction?,
        orderedPaymentMethodTypes: [STPPaymentMethodType],
        paymentMethodID: String?,
        paymentMethod: STPPaymentMethod?,
        paymentMethodOptions: STPPaymentMethodOptions?,
        paymentMethodTypes: [NSNumber],
        status: STPSetupIntentStatus,
        usage: STPSetupIntentUsage,
        lastSetupError: STPSetupIntentLastSetupError?,
        allResponseFields: [AnyHashable: Any],
        unactivatedPaymentMethodTypes: [STPPaymentMethodType]
    ) {
        self.stripeID = stripeID
        self.clientSecret = clientSecret
        self.created = created
        self.countryCode = countryCode
        self.customerID = customerID
        self.stripeDescription = stripeDescription
        self.linkSettings = linkSettings
        self.livemode = livemode
        self.nextAction = nextAction
        self.orderedPaymentMethodTypes = orderedPaymentMethodTypes
        self.paymentMethodID = paymentMethodID
        self.paymentMethod = paymentMethod
        self.paymentMethodOptions = paymentMethodOptions
        self.paymentMethodTypes = paymentMethodTypes
        self.status = status
        self.usage = usage
        self.lastSetupError = lastSetupError
        self.allResponseFields = allResponseFields
        self.unactivatedPaymentMethodTypes = unactivatedPaymentMethodTypes
        super.init()
    }

    /// :nodoc:
    @objc override public var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPSetupIntent.self), self),
            // Identifier
            "stripeId = \(stripeID)",
            // SetupIntent details (alphabetical)
            "clientSecret = <redacted>",
            "created = \(String(describing: created))",
            "countryCode = \(String(describing: countryCode))",
            "customerId = \(customerID ?? "")",
            "description = \(stripeDescription ?? "")",
            "lastSetupError = \(String(describing: lastSetupError))",
            "linkSettings = \(String(describing: linkSettings))",
            "livemode = \(livemode ? "YES" : "NO")",
            "nextAction = \(String(describing: nextAction))",
            "paymentMethodId = \(paymentMethodID ?? "")",
            "paymentMethod = \(String(describing: paymentMethod))",
            "paymentMethodOptions = \(String(describing: paymentMethodOptions))",
            "paymentMethodTypes = \(allResponseFields.stp_array(forKey: "payment_method_types") ?? [])",
            "status = \(allResponseFields.stp_string(forKey: "status") ?? "")",
            "usage = \(allResponseFields.stp_string(forKey: "usage") ?? "")",
            "unactivatedPaymentMethodTypes = \(allResponseFields.stp_array(forKey: "unactivated_payment_method_types") ?? [])",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPSetupIntentEnum support
    class func status(from string: String) -> STPSetupIntentStatus {
        let map = [
            "requires_payment_method": NSNumber(
                value: STPSetupIntentStatus.requiresPaymentMethod.rawValue
            ),
            "requires_confirmation": NSNumber(
                value: STPSetupIntentStatus.requiresConfirmation.rawValue
            ),
            "requires_action": NSNumber(value: STPSetupIntentStatus.requiresAction.rawValue),
            "processing": NSNumber(value: STPSetupIntentStatus.processing.rawValue),
            "succeeded": NSNumber(value: STPSetupIntentStatus.succeeded.rawValue),
            "canceled": NSNumber(value: STPSetupIntentStatus.canceled.rawValue),
        ]

        let key = string.lowercased()
        let statusNumber = map[key] ?? NSNumber(value: STPSetupIntentStatus.unknown.rawValue)
        return (STPSetupIntentStatus(rawValue: statusNumber.intValue))!
    }

    class func usage(from string: String) -> STPSetupIntentUsage {
        let map = [
            "off_session": NSNumber(value: STPSetupIntentUsage.offSession.rawValue),
            "on_session": NSNumber(value: STPSetupIntentUsage.onSession.rawValue),
        ]

        let key = string.lowercased()
        let statusNumber = map[key] ?? NSNumber(value: STPSetupIntentUsage.unknown.rawValue)
        return (STPSetupIntentUsage(rawValue: statusNumber.intValue))!
    }

    @objc @_spi(STP) public class func id(fromClientSecret clientSecret: String) -> String? {
        // see parseClientSecret from stripe-js-v3
        let components = clientSecret.components(separatedBy: "_secret_")
        if components.count >= 2 && components[0].hasPrefix("seti_") {
            return components[0]
        } else {
            return nil
        }
    }

    // MARK: - STPAPIResponseDecodable
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        // Consolidates expanded setup_intent and ordered_payment_method_types into singular dict for decoding
        if let paymentMethodPrefDict = response["payment_method_preference"] as? [AnyHashable: Any],
            let setupIntentDict = paymentMethodPrefDict["setup_intent"] as? [AnyHashable: Any],
            let orderedPaymentMethodTypes = paymentMethodPrefDict["ordered_payment_method_types"]
                as? [String]
        {
            var dict = setupIntentDict
            dict["ordered_payment_method_types"] = orderedPaymentMethodTypes
            dict["unactivated_payment_method_types"] = response["unactivated_payment_method_types"]
            dict["link_settings"] = response["link_settings"]
            return decodeSTPSetupIntentObject(fromAPIResponse: dict)
        } else {
            return decodeSTPSetupIntentObject(fromAPIResponse: response)
        }
    }

    class func decodeSTPSetupIntentObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()

        // required fields
        guard
            let stripeId = dict.stp_string(forKey: "id"),
            let clientSecret = dict.stp_string(forKey: "client_secret"),
            let rawStatus = dict.stp_string(forKey: "status"),
            let created = dict.stp_date(forKey: "created"),
            let paymentMethodTypeStrings = dict["payment_method_types"] as? [String],
            dict["livemode"] != nil
        else {
            return nil
        }

        let countryCode = dict.stp_string(forKey: "country_code")
        let customerID = dict.stp_string(forKey: "customer")
        let stripeDescription = dict.stp_string(forKey: "description")
        let linkSettings = LinkSettings.decodedObject(
            fromAPIResponse: dict["link_settings"] as? [AnyHashable: Any]
        )
        let livemode = dict.stp_bool(forKey: "livemode", or: true)
        let nextActionDict = dict.stp_dictionary(forKey: "next_action")
        let nextAction = STPIntentAction.decodedObject(fromAPIResponse: nextActionDict)
        let orderedPaymentMethodTypes = STPPaymentMethod.paymentMethodTypes(
            from: dict["ordered_payment_method_types"] as? [String] ?? paymentMethodTypeStrings
        )
        let paymentMethod = STPPaymentMethod.decodedObject(
            fromAPIResponse: dict["payment_method"] as? [AnyHashable: Any]
        )
        let paymentMethodID = paymentMethod?.stripeId ?? dict.stp_string(forKey: "payment_method")
        let paymentMethodOptions = STPPaymentMethodOptions.decodedObject(
            fromAPIResponse: dict["payment_method_options"] as? [AnyHashable: Any]
        )
        let paymentMethodTypes = STPPaymentMethod.types(from: paymentMethodTypeStrings)
        let status = self.status(from: rawStatus)
        let rawUsage = dict.stp_string(forKey: "usage")
        let usage = rawUsage != nil ? self.usage(from: rawUsage ?? "") : .none
        let lastSetupError = STPSetupIntentLastSetupError.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "last_setup_error")
        )
        let unactivatedPaymentTypes = STPPaymentMethod.paymentMethodTypes(
            from: dict["unactivated_payment_method_types"] as? [String] ?? []
        )

        let setupIntent = self.init(
            stripeID: stripeId,
            clientSecret: clientSecret,
            created: created,
            countryCode: countryCode,
            customerID: customerID,
            stripeDescription: stripeDescription,
            linkSettings: linkSettings,
            livemode: livemode,
            nextAction: nextAction,
            orderedPaymentMethodTypes: orderedPaymentMethodTypes,
            paymentMethodID: paymentMethodID,
            paymentMethod: paymentMethod,
            paymentMethodOptions: paymentMethodOptions,
            paymentMethodTypes: paymentMethodTypes,
            status: status,
            usage: usage,
            lastSetupError: lastSetupError,
            allResponseFields: response,
            unactivatedPaymentMethodTypes: unactivatedPaymentTypes
        )

        return setupIntent
    }
}
