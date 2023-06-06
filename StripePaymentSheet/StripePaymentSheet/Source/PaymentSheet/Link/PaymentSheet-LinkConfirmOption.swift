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
        /// Signup for Link then pay.
        case signUp(
            account: PaymentSheetLinkAccount,
            phoneNumber: PhoneNumber,
            legalName: String?,
            paymentMethodParams: STPPaymentMethodParams
        )

        /// Confirm with Payment Method ID.
        case withPaymentMethodID(
            paymentMethodID: String
        )

        var paymentSheetLabel: String {
            switch self {
            case .signUp(_, _, _, let paymentMethodParams):
                return paymentMethodParams.paymentSheetLabel
            case .withPaymentMethodID:
                return STPPaymentMethodType.link.displayName
            }
        }
    }
}
