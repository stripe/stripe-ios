//
//  STPAPIClient+ApplePay.swift
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeApplePay

/// STPAPIClient extensions to create Stripe Tokens, Sources, or PaymentMethods from Apple Pay PKPayment objects.
extension STPAPIClient {
    /// Converts a PKPayment object into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - payment:     The user's encrypted payment information as returned from a PKPaymentAuthorizationController. Cannot be nil.
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    public func createToken(with payment: PKPayment, completion: @escaping STPTokenCompletionBlock)
    {
        var params = payment.stp_tokenParameters(apiClient: self)
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
    public func createSource(
        with payment: PKPayment, completion: @escaping STPSourceCompletionBlock
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
