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
            legalName: String?,
            paymentMethodParams: STPPaymentMethodParams
        )

        /// Confirm intent with paymentDetails.
        case withPaymentDetails(
            account: PaymentSheetLinkAccount,
            paymentDetails: ConsumerPaymentDetails
        )

        /// Confirm with Payment Method Params.
        case withPaymentMethodParams(
            account: PaymentSheetLinkAccount,
            paymentMethodParams: STPPaymentMethodParams
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
        case .signUp(let account, _, _, _):
            return account
        case .withPaymentDetails(let account, _):
            return account
        case .withPaymentMethodParams(let account, _):
            return account
        case .withPaymentMethod:
            return nil
        }
    }

    var paymentSheetLabel: String {
        switch self {
        case .wallet, .withPaymentDetails:
            return STPPaymentMethodType.link.displayName
        case .signUp(_, _, _, let paymentMethodParams):
            return paymentMethodParams.paymentSheetLabel
        case .withPaymentMethodParams(_, let paymentMethodParams):
            return paymentMethodParams.paymentSheetLabel
        case .withPaymentMethod(let paymentMethod):
            return paymentMethod.paymentSheetLabel
        }
    }

}
