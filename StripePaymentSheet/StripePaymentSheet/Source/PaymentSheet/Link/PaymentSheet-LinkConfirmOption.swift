//
//  PaymentSheet-LinkConfirmOption.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 7/19/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension PaymentSheet {

    enum LinkConfirmOption {
        /// Present the Link wallet.
        case wallet

        /// Signup for Link then pay.
        case signUp(
            account: PaymentSheetLinkAccount,
            phoneNumber: PhoneNumber,
            consentAction: PaymentSheetLinkAccount.ConsentAction,
            legalName: String?,
            intentConfirmParams: IntentConfirmParams
        )

        /// Confirm with Payment Method.
        case withPaymentMethod(
            paymentMethod: STPPaymentMethod
        )
    }

}

// MARK: - Helpers

extension PaymentSheet.LinkConfirmOption {

    var account: PaymentSheetLinkAccount? {
        switch self {
        case .wallet:
            return nil
        case .signUp(let account, _, _, _, _):
            return account
        case .withPaymentMethod:
            return nil
        }
    }

    var paymentSheetLabel: String {
        switch self {
        case .wallet:
            return STPPaymentMethodType.link.displayName
        case .signUp(_, _, _, _, let intentConfirmParams):
            return intentConfirmParams.paymentMethodParams.paymentSheetLabel
        case .withPaymentMethod(let paymentMethod):
            return paymentMethod.paymentSheetLabel
        }
    }

    var billingDetails: STPPaymentMethodBillingDetails? {
        switch self {
        case .wallet:
            return nil
        case .signUp(_, _, _, _, let intentConfirmParams):
            return intentConfirmParams.paymentMethodParams.billingDetails
        case .withPaymentMethod(let paymentMethod):
            return paymentMethod.billingDetails
        }
    }

}
