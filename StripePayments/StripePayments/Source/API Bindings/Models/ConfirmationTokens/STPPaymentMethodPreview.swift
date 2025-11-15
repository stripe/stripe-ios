//
//  STPPaymentMethodPreview.swift
//  StripePayments
//
//  Created by Nick Porter on 9/4/25.
//

import Foundation

/// Preview of payment method details captured by the ConfirmationToken.
/// - seealso: https://docs.stripe.com/api/confirmation_tokens/object#confirmation_token_object-payment_method_preview
public class STPPaymentMethodPreview: NSObject, STPAPIResponseDecodable {
    /// You cannot directly instantiate an `STPPaymentMethodPreview`. You should only use one that is returned from the Stripe API.
    required internal override init() {
        super.init()
    }

    /// Type of the payment method.
    private(set) public var type: STPPaymentMethodType = .unknown

    /// Billing details for the payment method.
    private(set) public var billingDetails: STPPaymentMethodBillingDetails?

    /// This field indicates whether this payment method can be shown again to its customer in a checkout flow
    private(set) public var allowRedisplay: STPPaymentMethodAllowRedisplay = .unspecified

    /// The ID of the Customer to which this PaymentMethod is saved. Nil when the PaymentMethod has not been saved to a Customer.
    private(set) public var customerId: String?

    /// If this is a card PaymentMethod, this contains the user's card details.
    private(set) public var card: STPPaymentMethodCard?

    /// :nodoc:
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - STPAPIResponseDecodable

    @objc
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }

        // Required fields
        guard let typeString = response["type"] as? String else {
            return nil
        }

        let paymentMethodPreview = self.init()
        paymentMethodPreview.allResponseFields = response

        // Parse type
        paymentMethodPreview.type = STPPaymentMethod.type(from: typeString)

        // Parse billing details
        if let billingDetailsDict = response["billing_details"] as? [AnyHashable: Any] {
            paymentMethodPreview.billingDetails = STPPaymentMethodBillingDetails.decodedObject(fromAPIResponse: billingDetailsDict)
        } else {
            paymentMethodPreview.billingDetails = nil
        }

        // Parse allow redisplay
        paymentMethodPreview.allowRedisplay = STPPaymentMethod.allowRedisplay(from: response.stp_string(forKey: "allow_redisplay") ?? "")

        // Parse customer ID
        paymentMethodPreview.customerId = response["customer"] as? String

        if let cardDict = response["card"] as? [AnyHashable: Any] {
            paymentMethodPreview.card = STPPaymentMethodCard.decodedObject(fromAPIResponse: cardDict)
        } else {
            paymentMethodPreview.card = nil
        }

        return paymentMethodPreview
    }

    // MARK: - NSObject

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodPreview.self), self),
            // PaymentMethodPreview details
            "type = \(type.rawValue)",
            "billing_details = \(billingDetails?.description ?? "nil")",
            "allow_redisplay = \(allowRedisplay.rawValue)",
            "customer = \(customerId ?? "nil")",
            "card = \(card?.description ?? "nil")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }
}
