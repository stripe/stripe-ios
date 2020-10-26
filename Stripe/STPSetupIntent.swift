//
//  STPSetupIntent.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// A SetupIntent guides you through the process of setting up a customer's payment credentials for future payments.
/// - seealso: https://stripe.com/docs/api/setup_intents
public class STPSetupIntent: NSObject, STPAPIResponseDecodable {
  /// The Stripe ID of the SetupIntent.
  @objc public private(set) var stripeID: String
  /// The client secret of this SetupIntent. Used for client-side retrieval using a publishable key.
  @objc public private(set) var clientSecret: String
  /// Time at which the object was created.
  @objc public private(set) var created: Date?
  /// ID of the Customer this SetupIntent belongs to, if one exists.
  @objc public private(set) var customerID: String?
  /// An arbitrary string attached to the object. Often useful for displaying to users.
  @objc public private(set) var stripeDescription: String?
  /// Has the value `YES` if the object exists in live mode or the value `NO` if the object exists in test mode.
  @objc public private(set) var livemode = false
  /// If present, this property tells you what actions you need to take in order for your customer to set up this payment method.
  @objc public private(set) var nextAction: STPIntentAction?
  /// ID of the payment method used with this SetupIntent.
  @objc public private(set) var paymentMethodID: String?
  /// The list of payment method types (e.g. `[STPPaymentMethodType.card]`) that this SetupIntent is allowed to set up.
  @objc public private(set) var paymentMethodTypes: [NSNumber]?
  /// Status of this SetupIntent.
  @objc public private(set) var status: STPSetupIntentStatus = .unknown
  /// Indicates how the payment method is intended to be used in the future.
  @objc public private(set) var usage: STPSetupIntentUsage = .unknown
  /// The setup error encountered in the previous SetupIntent confirmation.
  @objc public private(set) var lastSetupError: STPSetupIntentLastSetupError?
  // MARK: - Deprecated

  /// Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
  /// @deprecated Metadata is not  returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead.
  /// - seealso: https://stripe.com/docs/api#metadata
  @available(
    *, deprecated,
    message:
      "Metadata is not returned to clients using publishable keys. Retrieve them on your server using your secret key instead."
  )
  @objc public private(set) var metadata: [String: String]?
  @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

  override required init() {
    self.stripeID = ""
    self.clientSecret = ""
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
      "customerId = \(customerID ?? "")",
      "description = \(stripeDescription ?? "")",
      "lastSetupError = \(String(describing: lastSetupError))",
      "livemode = \(livemode ? "YES" : "NO")",
      "nextAction = \(String(describing: nextAction))",
      "paymentMethodId = \(paymentMethodID ?? "")",
      "paymentMethodTypes = \((allResponseFields as NSDictionary).stp_array(forKey: "payment_method_types") ?? [])",
      "status = \((allResponseFields as NSDictionary).stp_string(forKey: "status") ?? "")",
      "usage = \((allResponseFields as NSDictionary).stp_string(forKey: "usage") ?? "")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - STPSetupIntentEnum support
  class func status(from string: String) -> STPSetupIntentStatus {
    let map = [
      "requires_payment_method": NSNumber(
        value: STPSetupIntentStatus.requiresPaymentMethod.rawValue),
      "requires_confirmation": NSNumber(value: STPSetupIntentStatus.requiresConfirmation.rawValue),
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

  @objc class func id(fromClientSecret clientSecret: String) -> String? {
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
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

    // required fields
    guard
      let stripeId = dict.stp_string(forKey: "id"),
      let clientSecret = dict.stp_string(forKey: "client_secret"),
      let rawStatus = dict.stp_string(forKey: "status"),
      dict["livemode"] != nil
    else {
      return nil
    }

    let setupIntent = self.init()

    setupIntent.stripeID = stripeId
    setupIntent.clientSecret = clientSecret
    setupIntent.created = dict.stp_date(forKey: "created")
    setupIntent.customerID = dict.stp_string(forKey: "customer")
    setupIntent.stripeDescription = dict.stp_string(forKey: "description")
    setupIntent.livemode = dict.stp_bool(forKey: "livemode", or: true)
    let nextActionDict = dict.stp_dictionary(forKey: "next_action")
    setupIntent.nextAction = STPIntentAction.decodedObject(fromAPIResponse: nextActionDict)
    setupIntent.paymentMethodID = dict.stp_string(forKey: "payment_method")
    let rawPaymentMethodTypes =
      dict.stp_array(forKey: "payment_method_types")?.stp_arrayByRemovingNulls()
      as? [String]
    if let rawPaymentMethodTypes = rawPaymentMethodTypes {
      setupIntent.paymentMethodTypes = STPPaymentMethod.types(from: rawPaymentMethodTypes)
    }
    setupIntent.status = self.status(from: rawStatus)
    let rawUsage = dict.stp_string(forKey: "usage")
    setupIntent.usage = rawUsage != nil ? self.usage(from: rawUsage ?? "") : .none
    setupIntent.lastSetupError = STPSetupIntentLastSetupError.decodedObject(
      fromAPIResponse: dict.stp_dictionary(forKey: "last_setup_error"))

    setupIntent.allResponseFields = response

    return setupIntent
  }
}
