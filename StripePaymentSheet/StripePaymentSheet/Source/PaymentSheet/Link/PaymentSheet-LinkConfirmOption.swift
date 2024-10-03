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
            details: LinkSignupDetails,
//            account: PaymentSheetLinkAccount,
//            phoneNumber: PhoneNumber,
//            consentAction: PaymentSheetLinkAccount.ConsentAction,
//            legalName: String?,
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

    // TODO: Can we get rid of this? Can we remove details from the signup case assoc val?
    var account: PaymentSheetLinkAccount? {
        switch self {
        case .wallet:
            return nil
        case .signUp(let details, _):
            return details.account
        case .withPaymentMethod:
            return nil
        }
    }

    var paymentSheetLabel: String {
        switch self {
        case .wallet:
            return STPPaymentMethodType.link.displayName
        case .signUp(_, let intentConfirmParams):
            return intentConfirmParams.paymentMethodParams.paymentSheetLabel
        case .withPaymentMethod(let paymentMethod):
            return paymentMethod.paymentSheetLabel
        }
    }

    var billingDetails: STPPaymentMethodBillingDetails? {
        switch self {
        case .wallet:
            return nil
        case .signUp(_, let intentConfirmParams):
            return intentConfirmParams.paymentMethodParams.billingDetails
        case .withPaymentMethod(let paymentMethod):
            return paymentMethod.billingDetails
        }
    }

}
