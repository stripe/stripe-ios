//
//  STPAPIClient+ApplePay.swift
//  StripePayments
//
//  Created by Jack Flintermann on 12/19/14.
//  Copyright © 2014 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore

/// STPAPIClient extensions to create Stripe Tokens, Sources, or PaymentMethods from Apple Pay PKPayment objects.
extension STPAPIClient {
    /// Converts a PKPayment object into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - payment:     The user's encrypted payment information as returned from a PKPaymentAuthorizationController. Cannot be nil.
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    @objc(createTokenWithPayment:completion:)
    public func createToken(with payment: PKPayment, completion: @escaping STPTokenCompletionBlock)
    {
        var params = payment.stp_tokenParameters(apiClient: self)
        STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
        createToken(
            withParameters: params,
            completion: completion
        )
        STPTelemetryClient.shared.sendTelemetryData()
    }

    /// Converts a PKPayment object into a Stripe source using the Stripe API.
    /// - Parameters:
    ///   - payment:     The user's encrypted payment information as returned from a PKPaymentAuthorizationController. Cannot be nil.
    ///   - completion:  The callback to run with the returned Stripe source (and any errors that may have occurred).
    @objc(createSourceWithPayment:completion:)
    public func createSource(
        with payment: PKPayment,
        completion: @escaping STPSourceCompletionBlock
    ) {
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
        with payment: PKPayment,
        completion: @escaping STPPaymentMethodCompletionBlock
    ) {
        createPaymentMethod(with: payment, metadata: [:], completion: completion)
    }

    /// Converts a PKPayment object into a Stripe Payment Method using the Stripe API.
    /// - Parameters:
    ///   - payment:     The user's encrypted payment information as returned from a PKPaymentAuthorizationController. Cannot be nil.
    ///   - metadata:    Additional data to be included with the payment method
    ///   - completion:  The callback to run with the returned Stripe source (and any errors that may have occurred).
    @objc(createPaymentMethodWithPayment:metadata:completion:)
    public func createPaymentMethod(
        with payment: PKPayment,
        metadata: [String: String],
        completion: @escaping STPPaymentMethodCompletionBlock
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
                    metadata: metadata
                )
                self.createPaymentMethod(with: paymentMethodParams, completion: completion)
            }
        }
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
}

extension PKPayment {
    func stp_tokenParameters(apiClient: STPAPIClient) -> [String: Any] {
        let paymentString = String(data: self.token.paymentData, encoding: .utf8)
        var payload: [String: Any] = [:]
        payload["pk_token"] = paymentString
        if let billingContact = self.billingContact {
            payload["card"] = billingContact.addressParams
        }

        assert(
            !((paymentString?.count ?? 0) == 0
                && apiClient.publishableKey?.hasPrefix("pk_live") ?? false),
            "The pk_token is empty. Using Apple Pay with an iOS Simulator while not in Stripe Test Mode will always fail."
        )

        let paymentInstrumentName = self.token.paymentMethod.displayName
        if let paymentInstrumentName = paymentInstrumentName {
            payload["pk_token_instrument_name"] = paymentInstrumentName
        }

        let paymentNetwork = self.token.paymentMethod.network
        if let paymentNetwork = paymentNetwork {
            // Note: As of SDK 20.0.0, this will return `PKPaymentNetwork(_rawValue: MasterCard)`.
            // We're intentionally leaving it this way: See RUN_MOBILESDK-125.
            payload["pk_token_payment_network"] = paymentNetwork
        }

        var transactionIdentifier = self.token.transactionIdentifier
        if transactionIdentifier != "" {
            if self.stp_isSimulated() {
                transactionIdentifier = PKPayment.stp_testTransactionIdentifier()
            }
            payload["pk_token_transaction_id"] = transactionIdentifier
        }

        return payload
    }
}
extension PKContact {
    @_spi(STP) public var addressParams: [AnyHashable: Any] {
        var params: [AnyHashable: Any] = [:]
        let stpAddress = STPAddress(pkContact: self)

        params["name"] = stpAddress.name
        params["address_line1"] = stpAddress.line1
        params["address_city"] = stpAddress.city
        params["address_state"] = stpAddress.state
        params["address_zip"] = stpAddress.postalCode
        params["address_country"] = stpAddress.country

        return params
    }
}

extension PKPayment {
    /// Returns true if the instance is a payment from the simulator.
    @_spi(STP) public func stp_isSimulated() -> Bool {
        return token.transactionIdentifier == "Simulated Identifier"
    }

    /// Returns a fake transaction identifier with the expected ~-separated format.
    @_spi(STP) public class func stp_testTransactionIdentifier() -> String {
        var uuid = UUID().uuidString
        uuid = uuid.replacingOccurrences(of: "~", with: "")

        // Simulated cards don't have enough info yet. For now, use a fake Visa number
        let number = "4242424242424242"

        // Without the original PKPaymentRequest, we'll need to use fake data here.
        let amount = NSDecimalNumber(string: "0")
        let cents = NSNumber(value: amount.multiplying(byPowerOf10: 2).intValue).stringValue
        let currency = "USD"
        let identifier = ["ApplePayStubs", number, cents, currency, uuid].joined(separator: "~")
        return identifier
    }
}
