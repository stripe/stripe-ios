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

        /// Confirm with Payment Method. (Web fallback)
        case withPaymentMethod(
            paymentMethod: STPPaymentMethod
        )

        /// Confirm intent with paymentDetails.
        case withPaymentDetails(
            account: PaymentSheetLinkAccount,
            paymentDetails: ConsumerPaymentDetails
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
        case .withPaymentDetails(let account, _):
            return account
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
        case .withPaymentDetails(_, let paymentDetails):
            return paymentDetails.paymentSheetLabel
        }
    }

    var paymentMethodType: String {
        switch self {
        case .wallet:
            return STPPaymentMethodType.link.identifier
        case .signUp(_, _, _, _, let intentConfirmParams):
            return intentConfirmParams.paymentMethodParams.type.identifier
        case .withPaymentMethod:
            return STPPaymentMethodType.link.identifier
        case .withPaymentDetails:
            return STPPaymentMethodType.link.identifier
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
        case .withPaymentDetails(_, let paymentDetails):
            return STPPaymentMethodBillingDetails(billingAddress: paymentDetails.billingAddress, email: paymentDetails.billingEmailAddress)
        }
    }

}
