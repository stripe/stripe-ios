//
//  ConfirmationMetadata+ClientConstants.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/11/26.
//

import Foundation

/// The parts of a type's policy the server can't vary, because they name the SDK's own code: who performs next
/// actions, what a cancel also does, which fixed `payment_method_options` the native form sets, and card's rule for a
/// closed web view. They aren't in the `mobile_session` contract; `init(wire:type:)` merges them into every served
/// entry and description.
extension ConfirmationMetadata {
    struct ClientConstants: Equatable {
        var performer: Performer = .engine
        var onCancel: CancelSideEffect = .none
        var paymentMethodOptions: [Params.PaymentMethodOption] = []
        var paymentIntentAfterWebViewDismissed: StatusRules?
        var setupIntentAfterWebViewDismissed: StatusRules?
    }

    /// Keyed by payment method type. Every other type uses the defaults.
    static let clientConstantsByType: [String: ClientConstants] = [
        // Card and Link: STPPaymentHandler performs every next action (3DS2, 3DS redirects) and cancels the 3DS source.
        // After the customer closes card's web view, STPPaymentHandler polls a `processing` intent for 30 seconds.
        "card": ClientConstants(
            performer: .stripePaymentHandler,
            onCancel: .cancel3DSSource,
            paymentMethodOptions: [.cardCVCRecollection, .cardNetwork],
            paymentIntentAfterWebViewDismissed: StatusRules(processing: .poll(seconds: 30, onTimeout: .succeed), requiresAction: .cancel),
            setupIntentAfterWebViewDismissed: StatusRules(processing: .poll(seconds: 30, onTimeout: .fail), requiresAction: .cancel)
        ),
        "link": ClientConstants(performer: .stripePaymentHandler, onCancel: .cancel3DSSource),
        "us_bank_account": ClientConstants(paymentMethodOptions: [.usBankAccountVerificationMethod]),
    ]

    static func clientConstants(for type: String) -> ClientConstants {
        return clientConstantsByType[type] ?? ClientConstants()
    }

    mutating func apply(_ constants: ClientConstants) {
        performer = constants.performer
        onCancel = constants.onCancel
        params.paymentMethodOptions = constants.paymentMethodOptions
        paymentIntent.afterWebViewDismissed = constants.paymentIntentAfterWebViewDismissed
        setupIntent?.afterWebViewDismissed = constants.setupIntentAfterWebViewDismissed
    }
}
