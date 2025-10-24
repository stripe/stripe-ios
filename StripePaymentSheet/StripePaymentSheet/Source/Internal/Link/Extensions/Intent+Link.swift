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
        guard let linkSettings, linkSettings.fundingSourcesSupportedByClient else {
            return false
        }
        return linkSettings.linkMode != nil
    }

    var linkPassthroughModeEnabled: Bool {
        linkSettings?.passthroughModeEnabled ?? false
    }

    var linkCardBrandFilteringEnabled: Bool {
        linkPassthroughModeEnabled
    }

    var supportsLinkCard: Bool {
        supportsLink && (linkFundingSources?.contains(.card) ?? false)
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

    var canSkipLinkWallet: Bool {
        linkFlags["link_mobile_skip_wallet_in_flow_controller"] ?? false
    }

    func shouldShowLink2FABeforePaymentSheet(for linkAccount: PaymentSheetLinkAccount) -> Bool {
        return self.supportsLink &&
        linkAccount.sessionState == .requiresVerification &&
        !linkAccount.hasStartedSMSVerification &&
        linkAccount.useMobileEndpoints &&
        self.linkSettings?.suppress2FAModal != true &&
        linkAccount.currentSession?.mobileFallbackWebviewParams?.webviewRequirementType != .required
    }

    var linkFlags: [String: Bool] {
        linkSettings?.linkFlags ?? [:]
    }

    var shouldShowPreferDebitCardHint: Bool {
        linkSettings?.linkShowPreferDebitCardHint ?? false
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

extension LinkSettings {
    /// Returns true if at least one of the `link_funding_sources` is supported by the client.
    var fundingSourcesSupportedByClient: Bool {
        let clientSupportedFundingSources = ConsumerPaymentDetails.DetailsType.allCases.compactMap(\.fundingSource)
        return !fundingSources.isDisjoint(with: clientSupportedFundingSources)
    }
}
