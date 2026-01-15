//
//  VoucherDisplayHandler.swift
//  StripePayments
//
//  Created by Claude Code on 2026-01-14.
//  Copyright 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// Handles authentication actions that display voucher information to the user.
///
/// This includes:
/// - OXXO (Mexico cash payment voucher)
/// - Boleto (Brazil bank slip)
/// - Multibanco (Portugal bank transfer reference)
/// - Konbini (Japan convenience store payment)
final class VoucherDisplayHandler: AuthenticationHandler {

    func canHandle(actionType: STPIntentActionType) -> Bool {
        switch actionType {
        case .OXXODisplayDetails,
             .boletoDisplayDetails,
             .multibancoDisplayDetails,
             .konbiniDisplayDetails:
            return true
        default:
            return false
        }
    }

    func handle(
        action: STPIntentAction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) {
        let hostedVoucherURL: URL?

        switch action.type {
        case .OXXODisplayDetails:
            hostedVoucherURL = action.oxxoDisplayDetails?.hostedVoucherURL

        case .boletoDisplayDetails:
            hostedVoucherURL = action.boletoDisplayDetails?.hostedVoucherURL

        case .multibancoDisplayDetails:
            hostedVoucherURL = action.multibancoDisplayDetails?.hostedVoucherURL

        case .konbiniDisplayDetails:
            hostedVoucherURL = action.konbiniDisplayDetails?.hostedVoucherURL

        default:
            currentAction.complete(
                with: .failed,
                error: createError(
                    for: .unsupportedAuthenticationErrorCode,
                    loggingSafeErrorMessage: "VoucherDisplayHandler cannot handle action type: \(action.type)"
                )
            )
            return
        }

        guard let url = hostedVoucherURL else {
            currentAction.complete(
                with: .failed,
                error: createError(
                    for: .unexpectedErrorCode,
                    loggingSafeErrorMessage: "Authentication action \(action.type) is missing expected details."
                )
            )
            return
        }

        paymentHandler._handleRedirect(to: url, withReturn: nil, useWebAuthSession: false)
    }
}
