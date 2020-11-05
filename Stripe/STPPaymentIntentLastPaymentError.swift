//
//  STPPaymentIntentLastPaymentError.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 8/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// The type of the error represented by `STPPaymentIntentLastPaymentError`.
/// Some STPPaymentIntentLastPaymentError properties are only populated for certain error types.
@objc public enum STPPaymentIntentLastPaymentErrorType: Int {

  /// An unknown error type.
  case unknown

  /// An error connecting to Stripe's API.
  @objc(STPPaymentIntentLastPaymentErrorTypeAPIConnection)
  case apiConnection

  /// An error with the Stripe API.
  @objc(STPPaymentIntentLastPaymentErrorTypeAPI)
  case api

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

  internal init(string: String) {
    switch string.lowercased() {
    case "api_connection_error":
      self = .apiConnection
    case "api_error":
      self = .api
    case "authentication_error":
      self = .authentication
    case "card_error":
      self = .card
    case "idempotency_error":
      self = .idempotency
    case "invalid_request_error":
      self = .invalidRequest
    case "rate_limit_error":
      self = .rateLimit
    default:
      self = .unknown
    }
  }
}

/// A value for `code` indicating the provided payment method failed authentication./// The payment error encountered in the previous PaymentIntent confirmation.
/// - seealso: https://stripe.com/docs/api/payment_intents/object#payment_intent_object-last_payment_error
public class STPPaymentIntentLastPaymentError: NSObject {

  /// A value for `code` indicating the provided payment method failed authentication.
  @objc public static let ErrorCodeAuthenticationFailure = "payment_intent_authentication_failure"

  /// For some errors that could be handled programmatically, a short string indicating the error code reported.
  /// - seealso: https://stripe.com/docs/error-codes
  @objc public let code: String?

  /// For card (`STPPaymentIntentLastPaymentErrorType.card`) errors resulting from a card issuer decline,
  /// a short string indicating the card issuer’s reason for the decline if they provide one.
  /// - seealso: https://stripe.com/docs/declines#issuer-declines
  @objc public let declineCode: String?

  /// A URL to more information about the error code reported.
  /// - seealso: https://stripe.com/docs/error-codes
  @objc public let docURL: String?

  /// A human-readable message providing more details about the error.
  /// For card (`STPPaymentIntentLastPaymentErrorType.card`) errors, these messages can be shown to your users.
  @objc public let message: String?

  /// If the error is parameter-specific, the parameter related to the error.
  /// For example, you can use this to display a message near the correct form field.
  @objc public let param: String?

  /// The PaymentMethod object for errors returned on a request involving a PaymentMethod.
  @objc public let paymentMethod: STPPaymentMethod?

  /// The type of error.
  @objc public let type: STPPaymentIntentLastPaymentErrorType

  /// :nodoc:
  @objc public let allResponseFields: [AnyHashable: Any]

  /// :nodoc:
  @objc public override var description: String {
    let props: [String] = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentIntentLastPaymentError.self), self),
      // PaymentIntentLastError details (alphabetical)
      "code = \(String(describing: code))",
      "declineCode = \(String(describing: declineCode))",
      "docURL = \(String(describing: docURL))",
      "message = \(String(describing: message))",
      "param = \(String(describing: param))",
      "paymentMethod = \(String(describing: paymentMethod))",
      "type = \(String(describing: allResponseFields["type"]))",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  private init(
    code: String?,
    declineCode: String?,
    docURL: String?,
    message: String?,
    param: String?,
    paymentMethod: STPPaymentMethod?,
    type: STPPaymentIntentLastPaymentErrorType,
    allResponseFields: [AnyHashable: Any]
  ) {
    self.code = code
    self.declineCode = declineCode
    self.docURL = docURL
    self.message = message
    self.param = param
    self.paymentMethod = paymentMethod
    self.type = type
    self.allResponseFields = allResponseFields
    super.init()
  }

}

// MARK: - STPAPIResponseDecodable
extension STPPaymentIntentLastPaymentError: STPAPIResponseDecodable {

  @objc
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let dict = response,
      let typeString = dict["type"] as? String
    else {
      return nil
    }

    return STPPaymentIntentLastPaymentError(
      code: dict["code"] as? String,
      declineCode: dict["decline_code"] as? String,
      docURL: dict["doc_url"] as? String,
      message: dict["message"] as? String,
      param: dict["param"] as? String,
      paymentMethod: STPPaymentMethod.decodedObject(
        fromAPIResponse: dict["payment_method"] as? [AnyHashable: Any]),
      type: STPPaymentIntentLastPaymentErrorType(string: typeString),
      allResponseFields: dict) as? Self
  }

}
