//
//  Intent+Link.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments

extension STPElementsSession {
    var supportsLink: Bool {
        // Either Link is an allowed Payment Method in the elements/sessions response, or passthrough mode (Link as a Card PM) is allowed
        orderedPaymentMethodTypes.contains(.link) || linkPassthroughModeEnabled
    }

    var linkPassthroughModeEnabled: Bool {
        linkSettings?.passthroughModeEnabled ?? false
    }

    var supportsLinkCard: Bool {
        supportsLink && (linkFundingSources?.contains(.card) ?? false) || linkPassthroughModeEnabled
    }

    var onlySupportsLinkBank: Bool {
        return supportsLink && (linkFundingSources == [.bankAccount])
    }

    var linkFundingSources: Set<LinkSettings.FundingSource>? {
        linkSettings?.fundingSources
    }

    var disableLinkSignup: Bool {
        linkSettings?.disableSignup ?? false
    }

    var linkPopupWebviewOption: LinkSettings.PopupWebviewOption {
        linkSettings?.popupWebviewOption ?? .shared
    }

    func shouldShowLink2FABeforePaymentSheet(for linkAccount: PaymentSheetLinkAccount) -> Bool {
        return self.supportsLink &&
        linkAccount.sessionState == .requiresVerification &&
        !linkAccount.hasStartedSMSVerification &&
        linkAccount.useMobileEndpoints &&
        self.linkSettings?.suppress2FAModal != true
    }

    func countryCode(overrideCountry: String?) -> String? {
#if DEBUG
        if let overrideCountry {
            return overrideCountry
        }
#endif
        return countryCode
    }

    var linkFlags: [String: Bool] {
        linkSettings?.linkFlags ?? [:]
    }
}

extension Intent {
    var callToAction: ConfirmButton.CallToActionType {
        switch self {
        case .paymentIntent(let paymentIntent):
            return .pay(amount: paymentIntent.amount, currency: paymentIntent.currency)
        case .setupIntent:
            return .setup
        case .deferredIntent(let intentConfig):
            switch intentConfig.mode {
            case .payment(let amount, let currency, _, _, _):
                return .pay(amount: amount, currency: currency)
            case .setup:
                return .setup
            }
        }
    }
}
