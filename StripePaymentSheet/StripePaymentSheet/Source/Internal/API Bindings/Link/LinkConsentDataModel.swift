//
//  LinkConsentDataModel.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/23/25.
//

import Foundation

struct LinkConsentDataModel: Decodable {
    struct Icon: Decodable {
        let defaultUrl: String

        enum CodingKeys: String, CodingKey {
            case defaultUrl = "default"
        }
    }

    struct ConsentPane: Decodable {
        struct ScopesSection: Decodable {
            struct Scope: Decodable {
                let icon: Icon?
                let header: String?
                let description: String
            }

            let header: String
            let scopes: [Scope]
        }

        let title: String
        let scopesSection: ScopesSection?
        let disclaimer: String?
        let denyButtonLabel: String?
        let allowButtonLabel: String

        enum CodingKeys: String, CodingKey {
            case title
            case scopesSection = "scopes_section"
            case disclaimer
            case denyButtonLabel = "deny_button_label"
            case allowButtonLabel = "allow_button_label"
        }
    }

    struct ConsentSection: Decodable {
        let disclaimer: String
    }

    let consentPane: ConsentPane?
    let consentSection: ConsentSection?

    enum CodingKeys: String, CodingKey {
        case consentPane = "consent_pane"
        case consentSection = "consent_section"
    }
}
