//
//  STPCheckoutSessionSavedPaymentMethodsOfferSave.swift
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

    /// The initial state of the checkbox.
    let status: Status

    /// Represents the initial checked state of the save checkbox.
    enum Status {
        /// Checkbox should be pre-checked (user has previously agreed to save).
        case accepted
        /// Checkbox should be unchecked by default.
        case notAccepted
    }

    static func decodedObject(from dict: [AnyHashable: Any]?) -> STPCheckoutSessionSavedPaymentMethodsOfferSave? {
        guard let dict = dict else {
            return nil
        }

        let enabled = dict["enabled"] as? Bool ?? false
        let statusString = dict["status"] as? String
        let status: Status = (statusString == "accepted") ? .accepted : .notAccepted

        return STPCheckoutSessionSavedPaymentMethodsOfferSave(
            enabled: enabled,
            status: status
        )
    }
}
