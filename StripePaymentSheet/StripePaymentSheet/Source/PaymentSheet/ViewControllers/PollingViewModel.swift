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
    var CTA: String
    var deadline: Date

    init(paymentMethodType: STPPaymentMethodType) {
        self.paymentMethodType = paymentMethodType
        self.CTA = PollingViewModel.computeCallToAction(paymentMethodType: paymentMethodType)
        self.deadline = PollingViewModel.computeDeadline(paymentMethodType: paymentMethodType)
    }

    private static func computeCallToAction(paymentMethodType: STPPaymentMethodType) -> String {
        switch paymentMethodType {
        case .UPI:
            return .Localized.open_upi_app
        default:
            fatalError("Polling CTA has not been implemented for \(paymentMethodType)")
        }
    }

    private static func computeDeadline(paymentMethodType: STPPaymentMethodType) -> Date {
        switch paymentMethodType {
        case .UPI:
            return Date().addingTimeInterval(60 * 5) // 5 minutes
        default:
            fatalError("Polling deadline has not been implemented for \(paymentMethodType)")
        }
    }
}
