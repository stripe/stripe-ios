//
//  SelectedPaymentSource.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/18/25.
//

import Foundation
import StripePayments

/// Represents the possible selected payment method types.
enum SelectedPaymentSource {

    /// Payment method was selected via Link UI, either credit/debit card or bank account.
    case link

    /// Apple Pay was selected as the payment method.
    case applePay(STPPaymentMethod)
}
