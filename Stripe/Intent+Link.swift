//
//  Intent+Link.swift
//  StripeiOS
//
//  Created by Ramon Torres on 11/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

extension Intent {
    var callToAction: ConfirmButton.CallToActionType {
        switch self {
        case .paymentIntent(let paymentIntent):
            return .pay(amount: paymentIntent.amount, currency: paymentIntent.currency)
        case .setupIntent(_):
            return .setup
        }
    }

    var linkBankOnboardingEnabled: Bool {
        switch self {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.linkSettings?.bankOnboardingEnabled ?? false
        case .setupIntent(let setupIntent):
            return setupIntent.linkSettings?.bankOnboardingEnabled ?? false
        }
    }

    var countryCode: String? {
        switch self {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.countryCode
        case .setupIntent(let setupIntent):
            return setupIntent.countryCode
        }
    }
}
