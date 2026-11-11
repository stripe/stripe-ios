//
//  PollingViewModel.swift
//  StripePaymentSheet
//
//  Created by Fionn Barrett on 08/08/2023.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripePaymentsUI
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

/// What `PollingViewController` shows and how often it polls.
class PollingViewModel {
    static let supportedPaymentMethods: [STPPaymentMethodType] = [.blik, .paynow, .promptPay, .mbWay, .bizum, .pix]

    /// The instructions under the title. With a countdown, `%@` is replaced with the time left.
    let CTA: String
    let showsCountdown: Bool
    let retryInterval: TimeInterval
    /// How long the screen polls before showing an error, counted from when `deadline` is first read.
    private let duration: TimeInterval
    lazy var deadline: Date = Date().addingTimeInterval(duration)

    /// The config STPPaymentHandler's polling next actions use (`PaymentSheetAuthenticationContext.presentPollingVCForAction`).
    /// `ConfirmationMetadata.native(for:)` has the same values; `ConfirmationMetadataParityTests` compares them.
    init(paymentMethodType: STPPaymentMethodType) {
        guard Self.supportedPaymentMethods.contains(paymentMethodType) else {
            fatalError("Unsupported payment type \(paymentMethodType) in PollingViewModel")
        }
        switch paymentMethodType {
        case .blik:
            CTA = .Localized.blik_confirm_payment
        case .paynow, .promptPay:
            CTA = .Localized.paynow_confirm_payment
        case .mbWay:
            CTA = .Localized.mb_way_confirm_payment
        case .bizum:
            CTA = .Localized.bizum_confirm_payment
        default:
            CTA = .Localized.pix_confirm_payment
        }
        showsCountdown = paymentMethodType != .pix
        switch paymentMethodType {
        case .blik:
            duration = 60 // 60 seconds
        case .paynow, .promptPay:
            duration = 60 * 60 // 1 hour
        case .bizum:
            // Keep in sync with:
            // https://stripe.sourcegraphcloud.com/stripe-internal/mint/-/blob/zoolander/src/java/com/stripe/fpintegrations/thirdpartyfpi/server/common/financialpartner/partner_configuration/config/bizum.textproto
            duration = 70 * 60 // 1 hour 10 minutes
        case .mbWay:
            // Keep in sync with:
            // https://stripe.sourcegraphcloud.com/stripe-internal/mint/-/blob/pay-server/lib/payment_flows/private/payment_methods/mb_way/constants.rb
            duration = 60 * 4 // 4 minutes
        default:
            // Pix. Used only when the API response does not include `expires_at`.
            duration = 60 * 60 * 24
        }
        switch paymentMethodType {
        case .pix:
            // Match Payment Element's Pix polling interval.
            retryInterval = 2
        default:
            // Payment Element polls Bizum every 3 seconds. Poll every second here to match the other iOS polling flows:
            // https://stripe.sourcegraphcloud.com/stripe-internal/mint/-/blob/pay-server/stripe-js-v3/src/stripeJs/intents/actions/awaitAuthorization/awaitAuthorization.ts
            retryInterval = 1
        }
    }

    /// The config from a payment method's confirmation metadata.
    init(screen: ConfirmationMetadata.NextAction.PollingScreen) {
        self.CTA = screen.instructions.localizedString
        self.showsCountdown = screen.showsCountdown
        self.retryInterval = TimeInterval(screen.intervalSeconds)
        self.duration = TimeInterval(screen.seconds)
    }
}

extension ConfirmationMetadata.NextAction.PollingScreen.Instructions {
    var localizedString: String {
        switch self {
        case .blik:
            return .Localized.blik_confirm_payment
        case .paynow:
            return .Localized.paynow_confirm_payment
        case .mbWay:
            return .Localized.mb_way_confirm_payment
        case .bizum:
            return .Localized.bizum_confirm_payment
        case .pix:
            return .Localized.pix_confirm_payment
        }
    }
}
