//
//  PaymentPagesAPIResponse+SavedPaymentMethodsOfferSave.swift
//  StripePaymentSheet
//
//  Created by George Birch on 2/17/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Controls whether the "Save for future use" checkbox is shown.
/// CheckoutClient returns this choice in `saved_payment_method_options.payment_method_save`.
struct STPCheckoutSessionSavedPaymentMethodsOfferSave {
    let enabled: Bool
}
