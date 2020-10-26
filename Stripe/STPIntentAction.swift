//
//  STPIntentAction.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

//
//  STPIntentNextAction.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Types of next actions for `STPPaymentIntent` and `STPSetupIntent`.
/// You shouldn't need to inspect this yourself; `STPPaymentHandler` will handle any next actions for you.
@objc public enum STPIntentActionType: Int {

  /// This is an unknown action that's been added since the SDK
  /// was last updated.
  /// Update your SDK, or use the `nextAction.allResponseFields`
  /// for custom handling.
  case unknown

  /// The payment intent needs to be authorized by the user. We provide
  /// `STPPaymentHandler` to handle the url redirections necessary.
  case redirectToURL

  /// The payment intent requires additional action handled by `STPPaymentHandler`.
  case useStripeSDK
  
  /// The action type is OXXO payment. We provide `STPPaymentHandler` to display
  /// the OXXO voucher.
  case OXXODisplayDetails

  /// Contains instructions for authenticating a payment by redirecting your customer to Alipay App or website.
  case alipayHandleRedirect

  /// Parse the string and return the correct `STPIntentActionType`,
  /// or `STPIntentActionTypeUnknown` if it's unrecognized by this version of the SDK.
  /// - Parameter string: the NSString with the `next_action.type`
  internal init(string: String) {
    switch string.lowercased() {
    case "redirect_to_url":
      self = .redirectToURL
    case "use_stripe_sdk":
      self = .useStripeSDK
    case "oxxo_display_details":
      self = .OXXODisplayDetails
    case "alipay_handle_redirect":
      self = .alipayHandleRedirect
    default:
      self = .unknown
    }
  }

  /// Return the string representing the provided `STPIntentActionType`.
  /// - Parameter actionType: the enum value to convert to a string
  /// - Returns: the string, or @"unknown" if this was an unrecognized type
  internal var stringValue: String {
    switch self {
    case .redirectToURL:
      return "redirect_to_url"
    case .useStripeSDK:
      return "use_stripe_sdk"
    case .OXXODisplayDetails:
      return "oxxo_display_details"
    case .alipayHandleRedirect:
      return "alipay_handle_redirection"
    case .unknown:
      break
    }

    // catch any unknown values here
    return "unknown"
  }
}

/// Next action details for `STPPaymentIntent` and `STPSetupIntent`.
/// This is a container for the various types that are available.
/// Check the `type` to see which one it is, and then use the related
/// property for the details necessary to handle it.
/// You cannot directly instantiate an `STPIntentAction`.
public class STPIntentAction: NSObject {

  /// The type of action needed. The value of this field determines which
  /// property of this object contains further details about the action.
  @objc public let type: STPIntentActionType

  /// The details for authorizing via URL, when `type == .redirectToURL`
  @objc public let redirectToURL: STPIntentActionRedirectToURL?
  
  /// The details for displaying OXXO voucher via URL, when `type == .oxxoDisplayDetails`
  @objc public let oxxoDisplayDetails: STPIntentActionOXXODisplayDetails?

  /// Contains instructions for authenticating a payment by redirecting your customer to Alipay App or website.
  @objc public let alipayHandleRedirect: STPIntentActionAlipayHandleRedirect?

  internal let useStripeSDK: STPIntentActionUseStripeSDK?

  /// :nodoc:
  @objc public let allResponseFields: [AnyHashable: Any]

  /// :nodoc:
  @objc public override var description: String {
    var props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPIntentAction.self), self),
      // Type
      "type = \(type.stringValue)",
    ]

    // omit properties that don't apply to this type
    switch type {
    case .redirectToURL:
      if let redirectToURL = redirectToURL {
        props.append("redirectToURL = \(redirectToURL)")
      }
    case .useStripeSDK:
      if let useStripeSDK = useStripeSDK {
        props.append("useStripeSDK = \(useStripeSDK)")
      }
    case .OXXODisplayDetails:
      if let oxxoDisplayDetails = oxxoDisplayDetails {
        props.append("oxxoDisplayDetails = \(oxxoDisplayDetails)")
      }
    case .alipayHandleRedirect:
      if let alipayHandleRedirect = alipayHandleRedirect {
        props.append("alipayHandleRedirect = \(alipayHandleRedirect)")
      }
    case .unknown:
      // unrecognized type, just show the original dictionary for debugging help
      props.append("allResponseFields = \(allResponseFields)")
    }

    return "<\(props.joined(separator: "; "))>"
  }

  internal init(
    type: STPIntentActionType,
    redirectToURL: STPIntentActionRedirectToURL?,
    alipayHandleRedirect: STPIntentActionAlipayHandleRedirect?,
    useStripeSDK: STPIntentActionUseStripeSDK?,
    oxxoDisplayDetails: STPIntentActionOXXODisplayDetails?,
    allResponseFields: [AnyHashable: Any]
  ) {
    self.type = type
    self.redirectToURL = redirectToURL
    self.alipayHandleRedirect = alipayHandleRedirect
    self.useStripeSDK = useStripeSDK
    self.oxxoDisplayDetails = oxxoDisplayDetails
    self.allResponseFields = allResponseFields
    super.init()
  }
}

// MARK: - STPAPIResponseDecodable
extension STPIntentAction: STPAPIResponseDecodable {

  @objc
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let dict = response,
      let rawType = dict["type"] as? String
    else {
      return nil
    }

    // Only set the type to a recognized value if we *also* have the expected sub-details.
    // ex: If the server said it was `.redirectToURL`, but decoding the
    // STPIntentActionRedirectToURL object fails, map type to `.unknown`
    var type = STPIntentActionType(string: rawType)
    var redirectToURL: STPIntentActionRedirectToURL?
    var alipayHandleRedirect: STPIntentActionAlipayHandleRedirect?
    var useStripeSDK: STPIntentActionUseStripeSDK?
    var oxxoDisplayDetails: STPIntentActionOXXODisplayDetails?

    switch type {
    case .unknown:
      break
    case .redirectToURL:
      redirectToURL = STPIntentActionRedirectToURL.decodedObject(
        fromAPIResponse: dict["redirect_to_url"] as? [AnyHashable: Any])
      if redirectToURL == nil {
        type = .unknown
      }
    case .useStripeSDK:
      useStripeSDK = STPIntentActionUseStripeSDK.decodedObject(
        fromAPIResponse: dict["use_stripe_sdk"] as? [AnyHashable: Any])
      if useStripeSDK == nil {
        type = .unknown
      }
    case .OXXODisplayDetails:
      oxxoDisplayDetails = STPIntentActionOXXODisplayDetails.decodedObject(
        fromAPIResponse: dict["oxxo_display_details"] as? [AnyHashable: Any])
      if oxxoDisplayDetails == nil {
        type = .unknown
      }
    case .alipayHandleRedirect:
      alipayHandleRedirect = STPIntentActionAlipayHandleRedirect.decodedObject(
        fromAPIResponse: dict["alipay_handle_redirect"] as? [AnyHashable: Any])
      if alipayHandleRedirect == nil {
        type = .unknown
      }
    }

    return STPIntentAction(
      type: type,
      redirectToURL: redirectToURL,
      alipayHandleRedirect: alipayHandleRedirect,
      useStripeSDK: useStripeSDK,
      oxxoDisplayDetails: oxxoDisplayDetails,
      allResponseFields: dict) as? Self
  }

}

// MARK: - Deprecated
extension STPIntentAction {
  /// The details for authorizing via URL, when `type == STPIntentActionTypeRedirectToURL`
  /// @deprecated Use `redirectToURL` instead.
  @available(*, deprecated, message: "Use `redirectToURL` instead.", renamed: "redirectToURL")
  @objc public var authorizeWithURL: STPIntentActionRedirectToURL? {
    return redirectToURL
  }
}
