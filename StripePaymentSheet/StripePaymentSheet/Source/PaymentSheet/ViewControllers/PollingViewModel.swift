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

    let paymentMethodType: STPPaymentMethodType
    let supportedPaymentMethods: [STPPaymentMethodType] = [.UPI, .blik, .paynow, .promptPay]
    lazy var CTA: String = {
        switch paymentMethodType {
        case .UPI:
            return .Localized.open_upi_app
        case .blik:
            return .Localized.blik_confirm_payment
        case .paynow, .promptPay:
            return .Localized.paynow_confirm_payment
        default:
            fatalError("Polling CTA has not been implemented for \(paymentMethodType)")
        }
    }()
    lazy var deadline: Date = {
        switch paymentMethodType {
        case .UPI:
            return Date().addingTimeInterval(60 * 5) // 5 minutes
        case .blik:
            return Date().addingTimeInterval(60) // 60 seconds
        case .paynow, .promptPay:
            return Date().addingTimeInterval(60 * 60) // 1 hour
        default:
            fatalError("Polling deadline has not been implemented for \(paymentMethodType)")
        }
    }()
    var retryInterval: TimeInterval {
        switch paymentMethodType {
        case .blik, .paynow, .promptPay:
            return 1
        case .UPI:
            return 10
        default:
            fatalError("Polling retry interval has not been implemented for \(paymentMethodType)")
        }
    }

    init(paymentMethodType: STPPaymentMethodType) {
        guard supportedPaymentMethods.contains(paymentMethodType) else {
               fatalError("Unsupported payment type \(paymentMethodType) in PollingViewModel")
        }
        self.paymentMethodType = paymentMethodType
    }
}
