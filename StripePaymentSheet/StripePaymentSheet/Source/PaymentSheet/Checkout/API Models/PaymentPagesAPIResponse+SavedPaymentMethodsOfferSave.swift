//
//  PaymentPagesAPIResponse+SavedPaymentMethodsOfferSave.swift
//  StripePaymentSheet
//
//  Created by George Birch on 2/17/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Controls whether the "Save for future use" checkbox is shown and its initial state.
///
/// This data comes from the checkout session's `customer_managed_saved_payment_methods_offer_save`
/// configuration, which is set when creating the checkout session.
struct STPCheckoutSessionSavedPaymentMethodsOfferSave {
    /// Whether the save checkbox should be shown to the user.
    let enabled: Bool

    static func decodedObject(from dict: [AnyHashable: Any]?) -> STPCheckoutSessionSavedPaymentMethodsOfferSave? {
        guard let dict = dict else {
            return nil
        }

        let enabled = dict["enabled"] as? Bool ?? false

        return STPCheckoutSessionSavedPaymentMethodsOfferSave(
            enabled: enabled
        )
    }
}
