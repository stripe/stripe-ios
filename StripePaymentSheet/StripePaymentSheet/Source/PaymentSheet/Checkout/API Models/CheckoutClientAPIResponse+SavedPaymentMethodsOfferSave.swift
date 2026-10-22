//
//  CheckoutClientAPIResponse+SavedPaymentMethodsOfferSave.swift
//  StripePaymentSheet
//
//  Created by George Birch on 2/17/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Controls whether Checkout shows the "Save for future use" checkbox.
/// CheckoutClient does not persist checkbox selection; the SDK keeps that state locally.
struct STPCheckoutSessionSavedPaymentMethodsOfferSave {
    let enabled: Bool
}
