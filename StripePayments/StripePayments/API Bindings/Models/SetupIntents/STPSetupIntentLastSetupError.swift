//
//  STPSetupIntentLastSetupError.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 8/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// The type of the error represented by `STPSetupIntentLastSetupError`.
/// Some STPSetupIntentLastError properties are only populated for certain error types.
@objc
public enum STPSetupIntentLastSetupErrorType: UInt {
    /// An unknown error type.
    case unknown
    /// An error connecting to Stripe's API.
    @objc(STPSetupIntentLastSetupErrorTypeAPIConnection)
    case apiConnection
    /// An error with the Stripe API.
    case API
    /// A failure to authenticate your customer.
    case authentication
    /// Card errors are the most common type of error you should expect to handle.
    /// They result when the user enters a card that can't be charged for some reason.
    /// Check the `declineCode` property for the decline code.  The `message` property contains a message you can show to your users.
    case card
    /// Keys for idempotent requests can only be used with the same parameters they were first used with.
    case idempotency
    /// Invalid request errors.  Typically, this is because your request has invalid parameters.
    case invalidRequest
    /// Too many requests hit the API too quickly.
    case rateLimit
}

// MARK: - Error Codes

/// A value for `code` indicating the provided payment method failed authentication./// The error encountered in the previous SetupIntent confirmation.
/// - seealso: https://stripe.com/docs/api/setup_intents/object#setup_intent_object-last_setup_error
public class STPSetupIntentLastSetupError: NSObject, STPAPIResponseDecodable {
    /// For some errors that could be handled programmatically, a short string indicating the error code reported.
    /// - seealso: https://stripe.com/docs/error-codes
    @objc public private(set) var code: String?
    /// For card (`STPSetupIntentLastSetupErrorTypeCard`) errors resulting from a card issuer decline,
    /// a short string indicating the card issuer’s reason for the decline if they provide one.
    /// - seealso: https://stripe.com/docs/declines#issuer-declines
    @objc public private(set) var declineCode: String?
    /// A URL to more information about the error code reported.
    /// - seealso: https://stripe.com/docs/error-codes
    @objc public private(set) var docURL: String?
    /// A human-readable message providing more details about the error.
    /// For card (`STPSetupIntentLastSetupErrorTypeCard`) errors, these messages can be shown to your users.
    @objc public private(set) var message: String?
    /// If the error is parameter-specific, the parameter related to the error.
    /// For example, you can use this to display a message near the correct form field.
    @objc public private(set) var param: String?
    /// The PaymentMethod object for errors returned on a request involving a PaymentMethod.
    @objc public private(set) var paymentMethod: STPPaymentMethod?
    /// The type of error.
    @objc public private(set) var type: STPSetupIntentLastSetupErrorType = .unknown
    @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPSetupIntentLastSetupError.self), self),
            // SetupIntentLastError details (alphabetical)
            "code = \(code ?? "")",
            "declineCode = \(declineCode ?? "")",
            "docURL = \(docURL ?? "")",
            "message = \(message ?? "")",
            "param = \(param ?? "")",
            "paymentMethod = \(String(describing: paymentMethod))",
            "type = \(String(describing: allResponseFields["type"]))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    @objc(typeFromString:)
    class func type(from string: String) -> STPSetupIntentLastSetupErrorType {
        let map = [
            "api_connection_error": NSNumber(
                value: STPSetupIntentLastSetupErrorType.apiConnection.rawValue
            ),
            "api_error": NSNumber(value: STPSetupIntentLastSetupErrorType.API.rawValue),
            "authentication_error": NSNumber(
                value: STPSetupIntentLastSetupErrorType.authentication.rawValue
            ),
            "card_error": NSNumber(value: STPSetupIntentLastSetupErrorType.card.rawValue),
            "idempotency_error": NSNumber(
                value: STPSetupIntentLastSetupErrorType.idempotency.rawValue
            ),
            "invalid_request_error": NSNumber(
                value: STPSetupIntentLastSetupErrorType.invalidRequest.rawValue
            ),
            "rate_limit_error": NSNumber(
                value: STPSetupIntentLastSetupErrorType.rateLimit.rawValue
            ),
        ]

        let key = string.lowercased()
        let statusNumber =
            map[key] ?? NSNumber(value: STPSetupIntentLastSetupErrorType.unknown.rawValue)
        return (STPSetupIntentLastSetupErrorType(rawValue: UInt(statusNumber.intValue)))!
    }

    // MARK: - STPAPIResponseDecodable
    override required init() {
        super.init()
    }

    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()
        let lastError = self.init()
        lastError.code = dict.stp_string(forKey: "code")
        lastError.declineCode = dict.stp_string(forKey: "decline_code")
        lastError.docURL = dict.stp_string(forKey: "doc_url")
        lastError.message = dict.stp_string(forKey: "message")
        lastError.param = dict.stp_string(forKey: "param")
        lastError.paymentMethod = STPPaymentMethod.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "payment_method")
        )
        lastError.type = self.type(from: dict.stp_string(forKey: "type") ?? "")
        lastError.allResponseFields = response

        return lastError
    }
}

// MARK: - `code` string values

@objc extension STPSetupIntentLastSetupError {
    /// A possible value for the `error` property.  The provided payment method has failed authentication. Provide a new payment method to attempt to fulfill this SetupIntent again.
    public static let CodeAuthenticationFailure = "setup_intent_authentication_failure"
}
