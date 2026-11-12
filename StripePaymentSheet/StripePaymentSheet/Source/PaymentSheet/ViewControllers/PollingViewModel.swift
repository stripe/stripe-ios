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

    let title: String
    /// The instructions under the title. With a countdown, `timeRemainingPlaceholder` is replaced with the time left.
    let CTA: String
    /// `%@` in the SDK's strings, `{time_remaining}` in the server's.
    let timeRemainingPlaceholder: String
    let cancelButtonTitle: String
    /// The title and instructions once the deadline passes without approval.
    let failureTitle: String
    let failureInstructions: String
    let showsCountdown: Bool
    let retryInterval: TimeInterval
    /// How long the screen polls before showing an error, counted from when `deadline` is first read.
    private let duration: TimeInterval
    lazy var deadline: Date = Date().addingTimeInterval(duration)

    /// The config STPPaymentHandler's polling next actions use (`PaymentSheetAuthenticationContext.presentPollingVCForAction`).
    /// The confirmation table's entries have the same values; `ConfirmationMetadataParityTests` compares them.
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
        title = .Localized.approve_payment
        timeRemainingPlaceholder = "%@"
        cancelButtonTitle = .Localized.cancel_pay_another_way
        failureTitle = .Localized.payment_failed
        failureInstructions = .Localized.please_go_back
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

    /// The config from a payment method's confirmation metadata, with the server's localized strings.
    init(screen: ConfirmationMetadata.NextAction.PollingScreen) {
        self.title = screen.title
        self.CTA = screen.instructions
        // The server's instructions are an ICU message whose only argument is the time left.
        self.timeRemainingPlaceholder = "{time_remaining}"
        self.cancelButtonTitle = screen.cancelButton
        self.failureTitle = screen.failureTitle
        self.failureInstructions = screen.failureInstructions
        self.showsCountdown = screen.showsCountdown
        self.retryInterval = TimeInterval(screen.intervalSeconds)
        self.duration = TimeInterval(screen.seconds)
    }

    /// `CTA` with the time left filled in.
    func instructions(timeRemaining: String) -> String {
        return CTA.replacingOccurrences(of: timeRemainingPlaceholder, with: timeRemaining)
    }
}
