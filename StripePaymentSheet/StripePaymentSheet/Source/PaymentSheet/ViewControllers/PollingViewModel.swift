//
//  PollingViewModel.swift
//  StripePaymentSheet
//
//  Created by Fionn Barrett on 08/08/2023.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

class PollingViewModel {

    let paymentMethodType: PaymentSheet.PaymentMethodType
    let supportedPaymentMethodTypes: [PaymentSheet.PaymentMethodType] = [.UPI, .dynamic("blik"), .dynamic("paynow")]
    lazy var CTA: String = {
        switch paymentMethodType {
        case .UPI:
            return .Localized.open_upi_app
        case .dynamic("blik"):
            return .Localized.blik_confirm_payment
        case .dynamic("paynow"):
            return .Localized.paynow_confirm_payment
        default:
            fatalError("Polling CTA has not been implemented for \(paymentMethodType)")
        }
    }()
    lazy var deadline: Date = {
        switch paymentMethodType {
        case .UPI:
            return Date().addingTimeInterval(60 * 5) // 5 minutes
        case .dynamic("blik"):
            return Date().addingTimeInterval(60) // 60 seconds
        case .dynamic("paynow"):
            return Date().addingTimeInterval(60 * 60) // 1 hour
        default:
            fatalError("Polling deadline has not been implemented for \(paymentMethodType)")
        }
    }()

    init(paymentMethodType: String) {
        let paymentMethodType: PaymentSheet.PaymentMethodType = .init(from: paymentMethodType)
        guard supportedPaymentMethodTypes.contains(paymentMethodType) else {
               fatalError("Unsupported payment type \(paymentMethodType) in PollingViewModel")
        }
        self.paymentMethodType = paymentMethodType
    }
}
