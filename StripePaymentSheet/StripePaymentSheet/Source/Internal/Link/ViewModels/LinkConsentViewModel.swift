//
//  LinkConsentViewModel.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/23/25.
//

import Foundation

enum LinkConsentViewModel {
    case inline(InlineConsentViewModel)
    case full(FullConsentViewModel)

    struct InlineConsentViewModel {
        let disclaimer: String
    }

    struct FullConsentViewModel {
        let title: String
        let merchantLogoURL: URL?
        let email: String
        let scopesSection: LinkConsentDataModel.ConsentPane.ScopesSection?
        let disclaimer: String?
        let denyButtonLabel: String?
        let allowButtonLabel: String

        var scopesSectionIfNotEmpty: LinkConsentDataModel.ConsentPane.ScopesSection? {
            guard let scopesSection else { return nil }
            guard !scopesSection.scopes.isEmpty else { return nil }
            return scopesSection
        }
    }

    init?(
        email: String,
        merchantLogoURL: URL?,
        dataModel: LinkConsentDataModel?
    ) {
        guard let dataModel else { return nil }

        if let consentPane = dataModel.consentPane {
            self = .full(
                FullConsentViewModel(
                    title: consentPane.title,
                    merchantLogoURL: merchantLogoURL,
                    email: email,
                    scopesSection: consentPane.scopesSection,
                    disclaimer: consentPane.disclaimer,
                    denyButtonLabel: consentPane.denyButtonLabel,
                    allowButtonLabel: consentPane.allowButtonLabel
                )
            )
        } else if let consentSection = dataModel.consentSection {
            self = .inline(
                InlineConsentViewModel(disclaimer: consentSection.disclaimer)
            )
        } else {
            return nil
        }
    }
}
