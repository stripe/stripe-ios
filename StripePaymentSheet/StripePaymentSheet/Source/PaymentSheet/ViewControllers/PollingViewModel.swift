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
    let supportedPaymentMethods: [STPPaymentMethodType] = [.blik, .paynow, .promptPay, .mbWay, .bizum]
    lazy var CTA: String = {
        switch paymentMethodType {
        case .blik:
            return .Localized.blik_confirm_payment
        case .paynow, .promptPay:
            return .Localized.paynow_confirm_payment
        case .mbWay:
            return .Localized.mb_way_confirm_payment
        case .bizum:
            return .Localized.bizum_confirm_payment
        default:
            fatalError("Polling CTA has not been implemented for \(paymentMethodType)")
        }
    }()
    lazy var deadline: Date = {
        switch paymentMethodType {
        case .blik:
            return Date().addingTimeInterval(60) // 60 seconds
        case .paynow, .promptPay:
            return Date().addingTimeInterval(60 * 60) // 1 hour
        case .bizum:
            // Keep in sync with:
            // https://stripe.sourcegraphcloud.com/stripe-internal/mint/-/blob/zoolander/src/java/com/stripe/fpintegrations/thirdpartyfpi/server/common/financialpartner/partner_configuration/config/bizum.textproto
            return Date().addingTimeInterval(70 * 60) // 1 hour 10 minutes
        case .mbWay:
            // Keep in sync with:
            // https://stripe.sourcegraphcloud.com/stripe-internal/mint/-/blob/pay-server/lib/payment_flows/private/payment_methods/mb_way/constants.rb
            return Date().addingTimeInterval(60 * 4) // 4 minutes
        default:
            fatalError("Polling deadline has not been implemented for \(paymentMethodType)")
        }
    }()
    var retryInterval: TimeInterval {
        switch paymentMethodType {
        case .blik, .paynow, .promptPay, .mbWay:
            return 1
        case .bizum:
            // Payment Element polls every 3 seconds. Poll every second here to match the other iOS polling flows:
            // https://stripe.sourcegraphcloud.com/stripe-internal/mint/-/blob/pay-server/stripe-js-v3/src/stripeJs/intents/actions/awaitAuthorization/awaitAuthorization.ts
            return 1
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
