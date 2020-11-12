//
//  STPPaymentIntentParams.swift
//  Stripe
//
//  Created by Daniel Jackson on 7/3/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to confirm a PaymentIntent object.
/// A PaymentIntent must have a PaymentMethod or Source associated in order to successfully confirm it.
/// That PaymentMethod or Source can either be:
/// - created during confirmation, by passing in a `STPPaymentMethodParams` or `STPSourceParams` object in the `paymentMethodParams` or `sourceParams` field
/// - a pre-existing PaymentMethod or Source can be associated by passing its id in the `paymentMethodId` or `sourceId` field
/// - or already set via your backend, either when creating or updating the PaymentIntent
/// - seealso: https://stripe.com/docs/api#confirm_payment_intent
public class STPPaymentIntentParams: NSObject {

  /// Initialize this `STPPaymentIntentParams` with a `clientSecret`, which is the only required
  /// field.
  /// - Parameter clientSecret: the client secret for this PaymentIntent
  @objc
  public init(clientSecret: String) {
    self.clientSecret = clientSecret
    super.init()
  }

  @objc convenience override init() {
    self.init(clientSecret: "")
  }

  /// The Stripe id of the PaymentIntent, extracted from the clientSecret.
  @objc public var stripeId: String? {
    return STPPaymentIntent.id(fromClientSecret: clientSecret)
  }

  /// The client secret of the PaymentIntent. Required
  @objc public var clientSecret: String

  /// Provide a supported `STPPaymentMethodParams` object, and Stripe will create a
  /// PaymentMethod during PaymentIntent confirmation.
  /// @note alternative to `paymentMethodId`
  @objc public var paymentMethodParams: STPPaymentMethodParams?

  /// Provide an already created PaymentMethod's id, and it will be used to confirm the PaymentIntent.
  /// @note alternative to `paymentMethodParams`
  @objc public var paymentMethodId: String?

  /// Provide a supported `STPSourceParams` object into here, and Stripe will create a Source
  /// during PaymentIntent confirmation.
  /// @note alternative to `sourceId`
  @objc public var sourceParams: STPSourceParams?

  /// Provide an already created Source's id, and it will be used to confirm the PaymentIntent.
  /// @note alternative to `sourceParams`
  @objc public var sourceId: String?

  /// Email address that the receipt for the resulting payment will be sent to.
  @objc public var receiptEmail: String?

  /// `@YES` to save this PaymentIntent’s PaymentMethod or Source to the associated Customer,
  /// if the PaymentMethod/Source is not already attached.
  /// This should be a boolean NSNumber, so that it can be `nil`
  @objc public var savePaymentMethod: NSNumber?

  /// The URL to redirect your customer back to after they authenticate or cancel
  /// their payment on the payment method’s app or site.
  /// This should probably be a URL that opens your iOS app.
  @objc public var returnURL: String?

  /// When provided, this property indicates how you intend to use the payment method that your customer provides after the current payment completes.
  /// If applicable, additional authentication may be performed to comply with regional legislation or network rules required to enable the usage of the same payment method for additional payments.
  public var setupFutureUsage: STPPaymentIntentSetupFutureUsage?
  
  /// When provided, this property indicates how you intend to use the payment method that your customer provides after the current payment completes.
  /// If applicable, additional authentication may be performed to comply with regional legislation or network rules required to enable the usage of the same payment method for additional payments.
  /// This property should only be used in Objective-C. In Swift, use `setupFutureUsage`.
  /// - seealso: STPPaymentIntentSetupFutureUsage for more details on what values you can provide.
  @available(swift, obsoleted: 1.0, renamed: "setupFutureUsage")
  @objc(setupFutureUsage) public var setupFutureUsage_objc: NSNumber? {
    get {
      setupFutureUsage?.rawValue as NSNumber?
    }
    set {
      setupFutureUsage = newValue.map { STPPaymentIntentSetupFutureUsage(rawValue: Int(truncating: $0)) } as? STPPaymentIntentSetupFutureUsage
    }
  }

  /// A boolean number to indicate whether you intend to use the Stripe SDK's functionality to handle any PaymentIntent next actions.
  /// If set to false, STPPaymentIntent.nextAction will only ever contain a redirect url that can be opened in a webview or mobile browser.
  /// When set to true, the nextAction may contain information that the Stripe SDK can use to perform native authentication within your
  /// app.
  @objc public var useStripeSDK: NSNumber?

  internal var _mandateData: STPMandateDataParams?
  /// Details about the Mandate to create.
  /// @note If this value is null and the (self.paymentMethod.type == STPPaymentMethodTypeSEPADebit | | self.paymentMethodParams.type == STPPaymentMethodTypeAUBECSDebit || self.paymentMethodParams.type == STPPaymentMethodTypeBacsDebit) && self.mandate == nil`, the SDK will set this to an internal value indicating that the mandate data should be inferred from the current context.
@objc public var mandateData: STPMandateDataParams? {
    set {
      _mandateData = newValue
    }
    get {
      if let _mandateData = _mandateData {
        return _mandateData
      } else if let params = paymentMethodParams,
        params.type == .SEPADebit || params.type == .bacsDebit || params.type == .AUBECSDebit
      {
        // Create default infer from client mandate_data
        let onlineParams = STPMandateOnlineParams(ipAddress: "", userAgent: "")
        onlineParams.inferFromClient = NSNumber(value: true)

        if let customerAcceptance = STPMandateCustomerAcceptanceParams(
          type: .online, onlineParams: onlineParams)
        {

          return STPMandateDataParams(customerAcceptance: customerAcceptance)
        }
      }
      return nil
    }
  }

  /// Options to update the associated PaymentMethod during confirmation.
  /// - seealso: STPConfirmPaymentMethodOptions
  @objc public var paymentMethodOptions: STPConfirmPaymentMethodOptions?

  /// Shipping information.
  @objc public var shipping: STPPaymentIntentShippingDetailsParams?

  /// The URL to redirect your customer back to after they authenticate or cancel
  /// their payment on the payment method’s app or site.
  /// This property has been renamed to `returnURL` and deprecated.
  @available(*, deprecated, renamed: "returnURL")
  @objc public var returnUrl: String? {
    get {
      return returnURL
    }
    set(returnUrl) {
      returnURL = returnUrl
    }
  }
  /// `@YES` to save this PaymentIntent’s Source to the associated Customer,
  /// if the Source is not already attached.
  /// This should be a boolean NSNumber, so that it can be `nil`
  /// This property has been renamed to `savePaymentMethod` and deprecated.
  @available(*, deprecated, renamed: "savePaymentMethod")
  @objc public var saveSourceToCustomer: NSNumber? {
    get {
      return savePaymentMethod
    }
    set(saveSourceToCustomer) {
      savePaymentMethod = saveSourceToCustomer
    }
  }

  /// :nodoc:
  @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

  /// Provide an STPPaymentResult from STPPaymentContext, and this will populate
  /// the proper field (either paymentMethodId or paymentMethodParams) for your PaymentMethod.
  @objc
  public func configure(with paymentResult: STPPaymentResult) {
    if let paymentMethod = paymentResult.paymentMethod {
      paymentMethodId = paymentMethod.stripeId
    } else if let params = paymentResult.paymentMethodParams {
      paymentMethodParams = params
    }
  }

  /// :nodoc:
  @objc public override var description: String {
    let props: [String] = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentIntentParams.self), self),
      // Identifier
      "stripeId = \(String(describing: stripeId))",
      // PaymentIntentParams details (alphabetical)
      "clientSecret = \((clientSecret.count > 0) ? "<redacted>" : "")",
      "receiptEmail = \(String(describing: receiptEmail))",
      "returnURL = \(String(describing: returnURL))",
      "savePaymentMethod = \(String(describing: savePaymentMethod?.boolValue))",
      "setupFutureUsage = \(String(describing: setupFutureUsage))",
      "shipping = \(String(describing: shipping))",
      "useStripeSDK = \(String(describing: useStripeSDK?.boolValue))",
      // Source
      "sourceId = \(String(describing: sourceId))",
      "sourceParams = \(String(describing: sourceParams))",
      // PaymentMethod
      "paymentMethodId = \(String(describing: paymentMethodId))",
      "paymentMethodParams = \(String(describing: paymentMethodParams))",
      // Mandate
      "mandateData = \(String(describing: mandateData))",
      // PaymentMethodOptions
      "paymentMethodOptions = @\(String(describing: paymentMethodOptions))",
      // Additional params set by app
      "additionalAPIParameters = \(additionalAPIParameters)",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  static internal let isClientSecretValidRegex: NSRegularExpression? = try? NSRegularExpression(
    pattern: "^pi_[^_]+_secret_[^_]+$", options: [])

  class internal func isClientSecretValid(_ clientSecret: String) -> Bool {

    return
      (isClientSecretValidRegex?.numberOfMatches(
        in: clientSecret,
        options: .anchored,
        range: NSRange(location: 0, length: clientSecret.count))) == 1
  }
}

// MARK: - STPFormEncodable
extension STPPaymentIntentParams: STPFormEncodable {

  @objc internal var setupFutureUsageRawString: String? {
    return setupFutureUsage?.stringValue
  }

  @objc
  public class func rootObjectName() -> String? {
    return nil
  }

  @objc
  public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [
      NSStringFromSelector(#selector(getter:clientSecret)): "client_secret",
      NSStringFromSelector(#selector(getter:paymentMethodParams)): "payment_method_data",
      NSStringFromSelector(#selector(getter:paymentMethodId)): "payment_method",
      NSStringFromSelector(#selector(getter:setupFutureUsageRawString)): "setup_future_usage",
      NSStringFromSelector(#selector(getter:sourceParams)): "source_data",
      NSStringFromSelector(#selector(getter:sourceId)): "source",
      NSStringFromSelector(#selector(getter:receiptEmail)): "receipt_email",
      NSStringFromSelector(#selector(getter:savePaymentMethod)): "save_payment_method",
      NSStringFromSelector(#selector(getter:returnURL)): "return_url",
      NSStringFromSelector(#selector(getter:useStripeSDK)): "use_stripe_sdk",
      NSStringFromSelector(#selector(getter:mandateData)): "mandate_data",
      NSStringFromSelector(#selector(getter:paymentMethodOptions)): "payment_method_options",
      NSStringFromSelector(#selector(getter:shipping)): "shipping",
    ]
  }
}

// MARK: - NSCopying
extension STPPaymentIntentParams: NSCopying {

  /// :nodoc:
  @objc
  public func copy(with zone: NSZone? = nil) -> Any {
    let copy = STPPaymentIntentParams(clientSecret: clientSecret)

    copy.paymentMethodParams = paymentMethodParams
    copy.paymentMethodId = paymentMethodId
    copy.sourceParams = sourceParams
    copy.sourceId = sourceId
    copy.receiptEmail = receiptEmail
    copy.savePaymentMethod = savePaymentMethod
    copy.returnURL = returnURL
    copy.setupFutureUsage = setupFutureUsage
    copy.useStripeSDK = useStripeSDK
    copy.mandateData = mandateData
    copy.paymentMethodOptions = paymentMethodOptions
    copy.shipping = shipping
    copy.additionalAPIParameters = additionalAPIParameters

    return copy
  }

}
