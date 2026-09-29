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

extension CheckoutController {
    func confirmApplePay(
        checkoutSession: Session,
        parameters: ApplePayConfirmationParameters
    ) async -> InternalConfirmResult {
        do {
            let context = try CheckoutApplePayContext.create(
                checkoutSession: checkoutSession,
                applePayConfirmationParameters: parameters,
                checkoutWalletUpdater: self
            )
            return await context.presentApplePay()
        } catch {
            return .failed(error)
        }
    }
}
