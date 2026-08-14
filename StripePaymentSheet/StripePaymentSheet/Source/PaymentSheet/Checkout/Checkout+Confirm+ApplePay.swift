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
        checkoutSession: Session,
        checkoutApplePayDataSource: CheckoutApplePayDataSource
    ) async -> InternalConfirmResult {
        do {
            let context = try CheckoutApplePayContext.create(
                checkoutSession: checkoutSession,
                checkoutApplePayDataSource: checkoutApplePayDataSource
            )
            return await context.presentApplePay()
        } catch {
            return .init(paymentSheetResult: .failed(error: error))
        }
    }
}
