//
//  STPAnalyticsClient.swift
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

class STPAnalyticsClient: NSObject {
  @objc static let sharedClient = STPAnalyticsClient()

  @objc internal var productUsage: Set<String> = Set()
  private var additionalInfoSet: Set<String> = Set()
  private var urlSession: URLSession = URLSession(
    configuration: STPAPIClient.sharedUrlSessionConfiguration)

  @objc class func tokenType(fromParameters parameters: [AnyHashable: Any]) -> String? {
    let parameterKeys = parameters.keys

    // these are currently mutually exclusive, so we can just run through and find the first match
    let tokenTypes = ["account", "bank_account", "card", "pii", "cvc_update"]
    if let type = tokenTypes.first(where: { parameterKeys.contains($0) }) {
      return type
    } else {
      return parameterKeys.contains("pk_token") ? "apple_pay" : nil
    }
  }

  func addClass(toProductUsageIfNecessary klass: AnyClass) {
    objc_sync_enter(self)
    _ = productUsage.insert(NSStringFromClass(klass.self))
    objc_sync_exit(self)
  }

  func addAdditionalInfo(_ info: String) {
    _ = additionalInfoSet.insert(info)
  }

  func clearAdditionalInfo() {
    additionalInfoSet.removeAll()
  }

  // MARK: - Card Scanning

  @objc class func shouldCollectAnalytics() -> Bool {
    #if targetEnvironment(simulator)
      return false
    #else
      return NSClassFromString("XCTest") == nil
    #endif
  }

  func additionalInfo() -> [String] {
    return additionalInfoSet.sorted()
  }

  func productUsageDictionary() -> [String: Any] {
    var usage: [String: Any] = [:]
    var productUsageCopy: Set<String>
    objc_sync_enter(self)
    productUsageCopy = productUsage
    objc_sync_exit(self)

    let uiUsageLevel: String
    if productUsageCopy.contains(NSStringFromClass(STPPaymentContext.self.self)) {
      uiUsageLevel = "full"
    } else if productUsageCopy.count == 1
      && productUsageCopy.contains(NSStringFromClass(STPPaymentCardTextField.self.self))
    {
      uiUsageLevel = "card_text_field"
    } else if productUsageCopy.count > 0 {
      uiUsageLevel = "partial"
    } else {
      uiUsageLevel = "none"
    }
    usage["ui_usage_level"] = uiUsageLevel
    usage["product_usage"] = productUsage.sorted()

    return usage
  }

  // MARK: - Card Metadata

  // MARK: - Card Scanning

  private func logPayload(_ payload: [String: Any]) {
    guard type(of: self).shouldCollectAnalytics(),
      let url = URL(string: "https://q.stripe.com")
    else {
      return
    }

    let request: NSMutableURLRequest = NSMutableURLRequest(url: url)

    request.stp_addParameters(toURL: payload)
    let task: URLSessionDataTask = urlSession.dataTask(with: request as URLRequest)
    task.resume()
  }
}

// MARK: - Helpers
extension STPAnalyticsClient {
  private class func commonPayload() -> [String: Any] {
    var payload: [String: Any] = [:]
    payload["bindings_version"] = STPAPIClient.STPSDKVersion
    payload["analytics_ua"] = "analytics.stripeios-1.0"
    let version = UIDevice.current.systemVersion
    if !version.isEmpty {
      payload["os_version"] = version
    }
    var systemInfo: utsname = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let deviceType = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
    if !deviceType.isEmpty {
      payload["device_type"] = deviceType
    }
    payload["app_name"] = Bundle.stp_applicationName() ?? ""
    payload["app_version"] = Bundle.stp_applicationVersion() ?? ""
    payload["apple_pay_enabled"] = NSNumber(value: StripeAPI.deviceSupportsApplePay())
    payload["ocr_type"] = "none"
    if #available(iOS 13.0, *) {
      if STPAnalyticsClient.sharedClient.productUsage.contains(
        NSStringFromClass(STPCardScanner.self.self))
      {
        payload["ocr_type"] = "stripe"
      }
    }

    return payload
  }

  private class func serializeConfiguration(_ configuration: STPPaymentConfiguration) -> [String:
    String]
  {
    var dictionary: [String: String] = [:]
    dictionary["publishable_key"] = STPAPIClient.shared.publishableKey ?? "unknown"

    if configuration.applePayEnabled && !configuration.fpxEnabled {
      dictionary["additional_payment_methods"] = "default"
    } else if !configuration.applePayEnabled && !configuration.fpxEnabled {
      dictionary["additional_payment_methods"] = "none"
    } else if !configuration.applePayEnabled && configuration.fpxEnabled {
      dictionary["additional_payment_methods"] = "fpx"
    } else if configuration.applePayEnabled && configuration.fpxEnabled {
      dictionary["additional_payment_methods"] = "applepay,fpx"
    }

    switch configuration.requiredBillingAddressFields {
    case .none:
      dictionary["required_billing_address_fields"] = "none"
    case .postalCode:
      dictionary["required_billing_address_fields"] = "zip"
    case .full:
      dictionary["required_billing_address_fields"] = "full"
    case .name:
      dictionary["required_billing_address_fields"] = "name"
    default:
      fatalError()
    }

    var shippingFields: [String] = []
    if let shippingAddressFields = configuration.requiredShippingAddressFields {
      if shippingAddressFields.contains(.name) {
        shippingFields.append("name")
      }
      if shippingAddressFields.contains(.emailAddress) {
        shippingFields.append("email")
      }
      if shippingAddressFields.contains(.postalAddress) {
        shippingFields.append("address")
      }
      if shippingAddressFields.contains(.phoneNumber) {
        shippingFields.append("phone")
      }
    }

    if shippingFields.isEmpty {
      shippingFields.append("none")
    }
    dictionary["required_shipping_address_fields"] = shippingFields.joined(separator: "_")

    switch configuration.shippingType {
    case .shipping:
      dictionary["shipping_type"] = "shipping"
    case .delivery:
      dictionary["shipping_type"] = "delivery"
    }

    dictionary["company_name"] = configuration.companyName
    dictionary["apple_merchant_identifier"] = configuration.appleMerchantIdentifier ?? "unknown"
    return dictionary
  }
}

// MARK: - Creation
extension STPAnalyticsClient {
  @objc(logTokenCreationAttemptWithConfiguration:tokenType:)
  func logTokenCreationAttempt(
    with configuration: STPPaymentConfiguration,
    tokenType: String?
  ) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.token_creation"
    payload["token_type"] = tokenType ?? "unknown"
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)
  }

  @objc(logSourceCreationAttemptWithConfiguration:sourceType:)
  func logSourceCreationAttempt(
    with configuration: STPPaymentConfiguration,
    sourceType: String?
  ) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.source_creationn"
    payload["source_type"] = sourceType ?? "unknown"
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)
  }

  @objc(logPaymentMethodCreationAttemptWithConfiguration:paymentMethodType:)
  func logPaymentMethodCreationAttempt(
    with configuration: STPPaymentConfiguration,
    paymentMethodType: String?
  ) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.payment_method_creation"
    payload["source_type"] = paymentMethodType ?? "unknown"
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)

  }
}

// MARK: - Confirmation
extension STPAnalyticsClient {
  @objc(logPaymentIntentConfirmationAttemptWithConfiguration:paymentMethodType:)
  func logPaymentIntentConfirmationAttempt(
    with configuration: STPPaymentConfiguration,
    paymentMethodType: String?
  ) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.payment_intent_confirmation"
    payload["source_type"] = paymentMethodType ?? "unknown"
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)
  }

  @objc(logSetupIntentConfirmationAttemptWithConfiguration:paymentMethodType:)
  func logSetupIntentConfirmationAttempt(
    with configuration: STPPaymentConfiguration,
    paymentMethodType: String?
  ) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.setup_intent_confirmation"
    payload["source_type"] = paymentMethodType ?? "unknown"
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)
  }
}

// MARK: - 3DS2 Flow
extension STPAnalyticsClient {
  @objc(log3DS2AuthenticateAttemptWithConfiguration:intentID:)
  func log3DS2AuthenticateAttempt(
    with configuration: STPPaymentConfiguration,
    intentID: String
  ) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.3ds2_authenticate"
    payload["intent_id"] = intentID
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)
  }

  @objc(log3DS2FrictionlessFlowWithConfiguration:intentID:)
  func log3DS2FrictionlessFlow(
    with configuration: STPPaymentConfiguration,
    intentID: String
  ) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.3ds2_frictionless_flow"
    payload["intent_id"] = intentID
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)
  }

  @objc(logURLRedirectNextActionWithConfiguration:intentID:)
  func logURLRedirectNextAction(
    with configuration: STPPaymentConfiguration,
    intentID: String
  ) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.url_redirect_next_action"
    payload["intent_id"] = intentID
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)
  }

  @objc(log3DS2ChallengeFlowPresentedWithConfiguration:intentID:uiType:)
  func log3DS2ChallengeFlowPresented(
    with configuration: STPPaymentConfiguration,
    intentID: String,
    uiType: String
  ) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.3ds2_challenge_flow_presented"
    payload["intent_id"] = intentID
    payload["3ds2_ui_type"] = uiType
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)
  }

  @objc(log3DS2ChallengeFlowTimedOutWithConfiguration:intentID:uiType:)
  func log3DS2ChallengeFlowTimedOut(
    with configuration: STPPaymentConfiguration,
    intentID: String,
    uiType: String
  ) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.3ds2_challenge_flow_timed_out"
    payload["intent_id"] = intentID
    payload["3ds2_ui_type"] = uiType
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)
  }

  @objc(log3DS2ChallengeFlowUserCanceledWithConfiguration:intentID:uiType:)
  func log3DS2ChallengeFlowUserCanceled(
    with configuration: STPPaymentConfiguration,
    intentID: String,
    uiType: String
  ) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.3ds2_challenge_flow_canceled"
    payload["intent_id"] = intentID
    payload["3ds2_ui_type"] = uiType
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)

  }

  @objc(log3DS2ChallengeFlowCompletedWithConfiguration:intentID:uiType:)
  func log3DS2ChallengeFlowCompleted(
    with configuration: STPPaymentConfiguration,
    intentID: String,
    uiType: String
  ) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.3ds2_challenge_flow_completed"
    payload["intent_id"] = intentID
    payload["3ds2_ui_type"] = uiType
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)
  }

  @objc(log3DS2ChallengeFlowErroredWithConfiguration:intentID:errorDictionary:)
  func log3DS2ChallengeFlowErrored(
    with configuration: STPPaymentConfiguration,
    intentID: String,
    errorDictionary: [AnyHashable: Any]
  ) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.3ds2_challenge_flow_errored"
    payload["intent_id"] = intentID
    payload["error_dictionary"] = errorDictionary
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)
  }
}

// MARK: - Card Metadata
extension STPAnalyticsClient {
  func logUserEnteredCompletePANBeforeMetadataLoaded(with configuration: STPPaymentConfiguration) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.card_metadata_loaded_too_slow"
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)
  }

  func logCardMetadataResponseFailure(with configuration: STPPaymentConfiguration) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.card_metadata_load_failure"
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)
  }

  func logCardMetadataMissingRange(with configuration: STPPaymentConfiguration) {
    let configurationDictionary = type(of: self).serializeConfiguration(configuration)
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.card_metadata_missing_range"
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    payload.merge(configurationDictionary) { (_, new) in new }

    logPayload(payload)
  }
}

// MARK: - Card Scanning
extension STPAnalyticsClient {
  func logCardScanSucceeded(withDuration duration: TimeInterval) {
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.cardscan_success"
    payload["duration"] = NSNumber(value: round(duration))
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    logPayload(payload)
  }

  func logCardScanCancelled(withDuration duration: TimeInterval) {
    var payload = type(of: self).commonPayload()
    payload["event"] = "stripeios.cardscan_cancel"
    payload["duration"] = NSNumber(value: round(duration))
    payload["additional_info"] = additionalInfo()

    payload.merge(productUsageDictionary()) { (_, new) in new }
    logPayload(payload)
  }
}
