//
//  STPPaymentConfiguration.swift
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

/// An `STPPaymentConfiguration` represents all the options you can set or change
/// around a payment.
/// You provide an `STPPaymentConfiguration` object to your `STPPaymentContext`
/// when making a charge. The configuration generally has settings that
/// will not change from payment to payment and thus is reusable, while the context
/// is specific to a single particular payment instance.
public class STPPaymentConfiguration: NSObject, NSCopying {
  /// This is a convenience singleton configuration that uses the default values for
  /// every property
  @objc(sharedConfiguration) public static var shared = STPPaymentConfiguration()

  private var _applePayEnabled = true
  /// The user is allowed to pay with Apple Pay if it's configured and available on their device.
  @objc public var applePayEnabled: Bool {
    get {
      return appleMerchantIdentifier != nil && _applePayEnabled
        && StripeAPI.deviceSupportsApplePay()
    }
    set {
      _applePayEnabled = newValue
    }
  }

  /// The user is allowed to pay with FPX.
  @objc public var fpxEnabled = false

  /// The billing address fields the user must fill out when prompted for their
  /// payment details. These fields will all be present on the returned PaymentMethod from
  /// Stripe.
  /// The default value is `STPBillingAddressFieldsPostalCode`.
  /// - seealso: https://stripe.com/docs/api/payment_methods/create#create_payment_method-billing_details
  @objc public var requiredBillingAddressFields = STPBillingAddressFields.postalCode
  /// The shipping address fields the user must fill out when prompted for their
  /// shipping info. Set to nil if shipping address is not required.
  /// The default value is nil.
  @objc public var requiredShippingAddressFields: Set<STPContactField>?
  /// Whether the user should be prompted to verify prefilled shipping information.
  /// The default value is YES.
  @objc public var verifyPrefilledShippingAddress = true
  /// The type of shipping for this purchase. This property sets the labels displayed
  /// when the user is prompted for shipping info, and whether they should also be
  /// asked to select a shipping method.
  /// The default value is STPShippingTypeShipping.
  @objc public var shippingType = STPShippingType.shipping
  /// The set of countries supported when entering an address. This property accepts
  /// a set of ISO 2-character country codes.
  /// The default value is all known countries. Setting this property will limit
  /// the available countries to your selected set.
  @objc public var availableCountries: Set<String> = Set<String>(NSLocale.isoCountryCodes)

  /// The name of your company, for displaying to the user during payment flows. For
  /// example, when using Apple Pay, the payment sheet's final line item will read
  /// "PAY {companyName}".
  /// The default value is the name of your iOS application which is derived from the
  /// `kCFBundleNameKey` of `Bundle.main`.
  @objc public var companyName = Bundle.stp_applicationName() ?? ""
  /// The Apple Merchant Identifier to use during Apple Pay transactions. To create
  /// one of these, see our guide at https://stripe.com/docs/mobile/apple-pay . You
  /// must set this to a valid identifier in order to automatically enable Apple Pay.
  @objc public var appleMerchantIdentifier: String?
  /// Determines whether or not the user is able to delete payment options
  /// This is only relevant to the `STPPaymentOptionsViewController` which, if
  /// enabled, will allow the user to delete payment options by tapping the "Edit"
  /// button in the navigation bar or by swiping left on a payment option and tapping
  /// "Delete". Currently, the user is not allowed to delete the selected payment
  /// option but this may change in the future.
  /// Default value is YES but will only work if `STPPaymentOptionsViewController` is
  /// initialized with a `STPCustomerContext` either through the `STPPaymentContext`
  /// or directly as an init parameter.
  @objc public var canDeletePaymentOptions = true
  /// Determines whether STPAddCardViewController allows the user to
  /// scan cards using the camera on devices running iOS 13 or later.
  /// To use this feature, you must also set the `NSCameraUsageDescription`
  /// value in your app's Info.plist.
  /// @note This feature is currently in beta. Please file bugs at
  /// https://github.com/stripe/stripe-ios/issues
  /// The default value is YES.
  @objc public var cardScanningEnabled = true
  // MARK: - Deprecated

  /// An enum value representing which payment options you will accept from your user
  /// in addition to credit cards.
  @available(
    *, deprecated,
    message:
      "additionalPaymentOptions has been removed. Set applePayEnabled and fpxEnabled on STPPaymentConfiguration instead."
  )
  @objc public var additionalPaymentOptions: Int = 0

  private var _publishableKey: String?
  /// If you used STPPaymentConfiguration.shared.publishableKey, use STPAPIClient.shared.publishableKey instead.  The SDK uses STPAPIClient.shared to make API requests by default.
  /// Your Stripe publishable key
  /// - seealso: https://dashboard.stripe.com/account/apikeys
  @available(*, deprecated, message: "If you used STPPaymentConfiguration.shared.publishableKey, use STPAPIClient.shared.publishableKey instead. If you passed a STPPaymentConfiguration instance to an SDK component, create an STPAPIClient, set publishableKey on it, and set the SDK component's APIClient property.")
  @objc public var publishableKey: String? {
    get {
      if self == STPPaymentConfiguration.shared {
        return STPAPIClient.shared.publishableKey
      }
      return _publishableKey ?? ""
    }
    set(publishableKey) {
      if self == STPPaymentConfiguration.shared {
        STPAPIClient.shared.publishableKey = publishableKey
      } else {
        _publishableKey = publishableKey
      }
    }
  }

  private var _stripeAccount: String?
  /// If you used STPPaymentConfiguration.shared.stripeAccount, use STPAPIClient.shared.stripeAccount instead.  The SDK uses STPAPIClient.shared to make API requests by default.
  /// In order to perform API requests on behalf of a connected account, e.g. to
  /// create charges for a connected account, set this property to the ID of the
  /// account for which this request is being made.
  /// - seealso: https://stripe.com/docs/payments/payment-intents/use-cases#connected-accounts
  @available(*, deprecated, message: "If you used STPPaymentConfiguration.shared.stripeAccount, use STPAPIClient.shared.stripeAccount instead. If you passed a STPPaymentConfiguration instance to an SDK component, create an STPAPIClient, set stripeAccount on it, and set the SDK component's APIClient property.")
  @objc public var stripeAccount: String? {
    get {
      if self == STPPaymentConfiguration.shared {
        return STPAPIClient.shared.stripeAccount
      }
      return _stripeAccount ?? ""
    }
    set(stripeAccount) {
      if self == STPPaymentConfiguration.shared {
        STPAPIClient.shared.stripeAccount = stripeAccount
      } else {
        _stripeAccount = stripeAccount
      }
    }
  }

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    var additionalPaymentOptionsDescription: String?

    var paymentOptions: [String] = []

    if _applePayEnabled {
      paymentOptions.append("STPPaymentOptionTypeApplePay")
    }

    if fpxEnabled {
      paymentOptions.append("STPPaymentOptionTypeFPX")
    }

    additionalPaymentOptionsDescription = paymentOptions.joined(separator: "|")

    var requiredBillingAddressFieldsDescription: String?

    switch requiredBillingAddressFields {
    case .none:
      requiredBillingAddressFieldsDescription = "STPBillingAddressFieldsNone"
    case .postalCode:
      requiredBillingAddressFieldsDescription = "STPBillingAddressFieldsPostalCode"
    case .full:
      requiredBillingAddressFieldsDescription = "STPBillingAddressFieldsFull"
    case .name:
      requiredBillingAddressFieldsDescription = "STPBillingAddressFieldsName"
    default:
      break
    }

    let requiredShippingAddressFieldsDescription = requiredShippingAddressFields?.map({
      $0.rawValue
    }).joined(separator: "|")

    var shippingTypeDescription: String?

    switch shippingType {
    case .shipping:
      shippingTypeDescription = "STPShippingTypeShipping"
    case .delivery:
      shippingTypeDescription = "STPShippingTypeDelivery"
    }

    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPPaymentConfiguration.self), self),
      // Basic configuration
      "additionalPaymentOptions = \(additionalPaymentOptionsDescription ?? "")",
      // Billing and shipping
      "requiredBillingAddressFields = \(requiredBillingAddressFieldsDescription ?? "")",
      "requiredShippingAddressFields = \(requiredShippingAddressFieldsDescription ?? "")",
      "verifyPrefilledShippingAddress = \((verifyPrefilledShippingAddress) ? "YES" : "NO")",
      "shippingType = \(shippingTypeDescription ?? "")",
      "availableCountries = \(availableCountries )",
      // Additional configuration
      "companyName = \(companyName )",
      "appleMerchantIdentifier = \(appleMerchantIdentifier ?? "")",
      "canDeletePaymentOptions = \((canDeletePaymentOptions) ? "YES" : "NO")",
      "cardScanningEnabled = \((cardScanningEnabled) ? "YES" : "NO")",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - NSCopying
  /// :nodoc:
  @objc
  public func copy(with zone: NSZone? = nil) -> Any {
    let copy = STPPaymentConfiguration()
    copy.applePayEnabled = _applePayEnabled
    copy.fpxEnabled = fpxEnabled
    copy.requiredBillingAddressFields = requiredBillingAddressFields
    copy.requiredShippingAddressFields = requiredShippingAddressFields
    copy.verifyPrefilledShippingAddress = verifyPrefilledShippingAddress
    copy.shippingType = shippingType
    copy.companyName = companyName
    copy.appleMerchantIdentifier = appleMerchantIdentifier
    copy.canDeletePaymentOptions = canDeletePaymentOptions
    copy.cardScanningEnabled = cardScanningEnabled
    copy.availableCountries = availableCountries
    copy._publishableKey = _publishableKey
    copy._stripeAccount = _stripeAccount
    return copy
  }
}
