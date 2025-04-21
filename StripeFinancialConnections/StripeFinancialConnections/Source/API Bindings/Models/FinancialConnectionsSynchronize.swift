//
//  FinancialConnectionsSynchronize.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/20/22.
//

import Foundation

struct FinancialConnectionsSynchronize: Decodable {
    let manifest: FinancialConnectionsSessionManifest
    let text: Text?
    let visual: VisualUpdate

    struct Text: Decodable {
        let accountPickerPane: FinancialConnectionsAccountPickerPane?
        let consentPane: FinancialConnectionsConsent?
        let networkingLinkSignupPane: FinancialConnectionsNetworkingLinkSignup?
        let linkLoginPane: FinancialConnectionsLinkLoginPane?
    }

    struct VisualUpdate: Decodable {
        let reducedBranding: Bool
        let merchantLogo: [String]
        let reduceManualEntryProminenceInErrors: Bool
    }
}
