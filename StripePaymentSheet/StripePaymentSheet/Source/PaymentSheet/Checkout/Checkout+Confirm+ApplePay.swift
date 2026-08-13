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
        checkout: CheckoutConfirmationInterface,
        authenticationContext: STPAuthenticationContext
    ) async -> InternalConfirmResult {
        do {
            let context = try CheckoutApplePayContext.create(
                checkout: checkout,
                authenticationContext: authenticationContext
            )
            return await context.presentApplePay()
        } catch {
            return .init(paymentSheetResult: .failed(error: error))
        }
    }
}
