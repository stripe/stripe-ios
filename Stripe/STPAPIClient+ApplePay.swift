//
//  STPAPIClient+ApplePay.swift
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//

import Foundation
import PassKit

/// STPAPIClient extensions to create Stripe Tokens, Sources, or PaymentMethods from Apple Pay PKPayment objects.
extension STPAPIClient {
  /// Converts a PKPayment object into a Stripe token using the Stripe API.
  /// - Parameters:
  ///   - payment:     The user's encrypted payment information as returned from a PKPaymentAuthorizationController. Cannot be nil.
  ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
  @objc(createTokenWithPayment:completion:)
  public func createToken(with payment: PKPayment, completion: @escaping STPTokenCompletionBlock) {
    var params = STPAPIClient.parameters(for: payment)
    STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
    createToken(
      withParameters: params,
      completion: completion)
    STPTelemetryClient.shared.sendTelemetryData()
  }

  /// Converts a PKPayment object into a Stripe source using the Stripe API.
  /// - Parameters:
  ///   - payment:     The user's encrypted payment information as returned from a PKPaymentAuthorizationController. Cannot be nil.
  ///   - completion:  The callback to run with the returned Stripe source (and any errors that may have occurred).
  @objc(createSourceWithPayment:completion:)
  public func createSource(with payment: PKPayment, completion: @escaping STPSourceCompletionBlock)
  {
    createToken(with: payment) { token, error in
      if token?.tokenId == nil || error != nil {
        completion(nil, error ?? NSError.stp_genericConnectionError())
      } else {
        let params = STPSourceParams()
        params.type = .card
        params.token = token?.tokenId
        self.createSource(with: params, completion: completion)
      }
    }
  }

  /// Converts a PKPayment object into a Stripe Payment Method using the Stripe API.
  /// - Parameters:
  ///   - payment:     The user's encrypted payment information as returned from a PKPaymentAuthorizationController. Cannot be nil.
  ///   - completion:  The callback to run with the returned Stripe source (and any errors that may have occurred).
  @objc(createPaymentMethodWithPayment:completion:)
  public func createPaymentMethod(
    with payment: PKPayment, completion: @escaping STPPaymentMethodCompletionBlock
  ) {
    createToken(with: payment) { token, error in
      if token?.tokenId == nil || error != nil {
        completion(nil, error ?? NSError.stp_genericConnectionError())
      } else {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.token = token?.tokenId
        let billingDetails = STPAPIClient.billingDetails(from: payment)
        let paymentMethodParams = STPPaymentMethodParams(
          card: cardParams,
          billingDetails: billingDetails,
          metadata: nil)
        self.createPaymentMethod(with: paymentMethodParams, completion: completion)
      }
    }

  }

  /// Converts Stripe errors into the appropriate Apple Pay error, for use in `PKPaymentAuthorizationResult`.
  /// If the error can be fixed by the customer within the Apple Pay sheet, we return an NSError that can be displayed in the Apple Pay sheet.
  /// Otherwise, the original error is returned, resulting in the Apple Pay sheet being dismissed. You should display the error message to the customer afterwards.
  /// Currently, we convert billing address related errors into a PKPaymentError that helpfully points to the billing address field in the Apple Pay sheet.
  /// Note that Apple Pay should prevent most card errors (e.g. invalid CVC, expired cards) when you add a card to the wallet.
  /// - Parameter stripeError:   An error from the Stripe SDK.
  public class func pkPaymentError(forStripeError stripeError: Error?) -> Error? {
    guard let stripeError = stripeError else {
      return nil
    }

    if (stripeError as NSError).domain == STPError.stripeDomain
      && ((stripeError as NSError).userInfo[STPError.cardErrorCodeKey] as? String
        == STPCardErrorCode.incorrectZip.rawValue)
    {
      var userInfo = (stripeError as NSError).userInfo
      var errorCode: PKPaymentError.Code = .unknownError
      errorCode = .billingContactInvalidError
      userInfo[PKPaymentErrorKey.postalAddressUserInfoKey.rawValue] = CNPostalAddressPostalCodeKey
      return NSError(domain: STPError.stripeDomain, code: errorCode.rawValue, userInfo: userInfo)
    }
    return stripeError
  }

  class func billingDetails(from payment: PKPayment) -> STPPaymentMethodBillingDetails? {
    var billingDetails: STPPaymentMethodBillingDetails?
    if payment.billingContact != nil {
      billingDetails = STPPaymentMethodBillingDetails()
      var billingAddress: STPAddress?
      if let billingContact = payment.billingContact {
        billingAddress = STPAddress(pkContact: billingContact)
      }
      billingDetails?.name = billingAddress?.name
      billingDetails?.email = billingAddress?.email
      billingDetails?.phone = billingAddress?.phone
      if payment.billingContact?.postalAddress != nil {
        if let billingAddress = billingAddress {
          billingDetails?.address = STPPaymentMethodAddress(address: billingAddress)
        }
      }
    }

    // The phone number and email in the "Contact" panel in the Apple Pay dialog go into the shippingContact,
    // not the billingContact. To work around this, we should fill the billingDetails' email and phone
    // number from the shippingDetails.
    if payment.shippingContact != nil {
      var shippingAddress: STPAddress?
      if let shippingContact = payment.shippingContact {
        shippingAddress = STPAddress(pkContact: shippingContact)
      }
      if billingDetails?.email == nil && shippingAddress?.email != nil {
        if billingDetails == nil {
          billingDetails = STPPaymentMethodBillingDetails()
        }
        billingDetails?.email = shippingAddress?.email
      }
      if billingDetails?.phone == nil && shippingAddress?.phone != nil {
        if billingDetails == nil {
          billingDetails = STPPaymentMethodBillingDetails()
        }
        billingDetails?.phone = shippingAddress?.phone
      }
    }

    return billingDetails
  }

  class func addressParams(from contact: PKContact?) -> [AnyHashable: Any]? {
    guard let contact = contact else {
      return nil
    }
    var params: [AnyHashable: Any] = [:]
    let stpAddress = STPAddress(pkContact: contact)

    params["name"] = stpAddress.name
    params["address_line1"] = stpAddress.line1
    params["address_city"] = stpAddress.city
    params["address_state"] = stpAddress.state
    params["address_zip"] = stpAddress.postalCode
    params["address_country"] = stpAddress.country

    return params
  }

  @objc(parametersForPayment:)
  class func parameters(for payment: PKPayment) -> [String: Any] {
    let paymentString = String(data: payment.token.paymentData, encoding: .utf8)
    var payload: [String: Any] = [:]
    payload["pk_token"] = paymentString
    if let billingContact = payment.billingContact {
      payload["card"] = self.addressParams(from: billingContact)
    }

    assert(
      !((paymentString?.count ?? 0) == 0
        && STPAPIClient.shared.publishableKey?.hasPrefix("pk_live") ?? false),
      "The pk_token is empty. Using Apple Pay with an iOS Simulator while not in Stripe Test Mode will always fail."
    )

    let paymentInstrumentName = payment.token.paymentMethod.displayName
    if let paymentInstrumentName = paymentInstrumentName {
      payload["pk_token_instrument_name"] = paymentInstrumentName
    }

    let paymentNetwork = payment.token.paymentMethod.network
    if let paymentNetwork = paymentNetwork {
      payload["pk_token_payment_network"] = paymentNetwork
    }

    var transactionIdentifier = payment.token.transactionIdentifier
    if transactionIdentifier != "" {
      if payment.stp_isSimulated() {
        transactionIdentifier = PKPayment.stp_testTransactionIdentifier() ?? ""
      }
      payload["pk_token_transaction_id"] = transactionIdentifier
    }

    return payload
  }

  // MARK: - Errors
}
