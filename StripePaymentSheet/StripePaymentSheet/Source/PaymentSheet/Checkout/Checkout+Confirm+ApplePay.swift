//
//  Checkout+Confirm+ApplePay.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 8/10/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension Checkout {
    static func confirmApplePay(
        checkout: Checkout,
        authenticationContext: STPAuthenticationContext
    ) async -> InternalConfirmResult {
        guard checkout.applePayContext == nil else {
            assertionFailure("Apple Pay is already in progress.")
            return .init(paymentSheetResult: .failed(error: CheckoutError.unknown(debugDescription: "Apple Pay is already in progress.")))
        }
        guard let context = CheckoutApplePayContext.create(
            checkout: checkout,
            authenticationContext: authenticationContext
        ) else {
            return .init(paymentSheetResult: .failed(error: CheckoutError.applePayNotConfigured))
        }
        checkout.applePayContext = context
        return await context.presentApplePay()
    }
}
