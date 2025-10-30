//
//  DocumentSide.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

enum DocumentSide: String {
    case front
    case back

    func instruction(availableIDTypes: [String]) -> String {

        func idDocument() -> String {
            if self == .front {
                return STPLocalizedString("8562c",
                    "Title of ID document scanning screen when scanning the front of an identity card"
                )
            } else {
                return STPLocalizedString("3229d",
                    "Title of ID document scanning screen when scanning the back of an identity card"
                )
            }
        }

        // Convert ID types to localized strings
        let localizedTypes = availableIDTypes.compactMap { $0.uiIDType() }

        // Handle specific combinations
        if localizedTypes.count == 2 {
            if localizedTypes.contains(String.Localized.driverLicense) && localizedTypes.contains(String.Localized.passport) {
                return self == .front ? String.Localized.frontOfDriverLicenseOrPassport : String(format: String.Localized.backOfSpecificDocument, String.Localized.driverLicense)
            } else if localizedTypes.contains(String.Localized.driverLicense) && localizedTypes.contains(String.Localized.governmentIssuedId) {
                return self == .front ? String.Localized.frontOfDriverLicenseOrGovernmentId : String.Localized.backOfDriverLicenseOrGovernmentId
            } else if localizedTypes.contains(String.Localized.passport) && localizedTypes.contains(String.Localized.governmentIssuedId) {
                return self == .front ? String.Localized.frontOfPassportOrGovernmentId : String(format: String.Localized.backOfSpecificDocument, String.Localized.governmentIssuedId)
            } else {
                // Fallback to generic text
                return idDocument()
            }
        } else if localizedTypes.count == 3 {
            // Handle all three types
            return self == .front ? String.Localized.frontOfAllIdTypes : String.Localized.backOfDriverLicenseOrGovernmentId
        } else if localizedTypes.count == 1, let type = localizedTypes.first {
            // Handle single type
            switch self {
            case .front:
                return String(format: String.Localized.frontOfSpecificDocument, type)
            case .back:
                return String(format: String.Localized.backOfSpecificDocument, type)
            }
        } else {
            // Fallback to generic text
            return idDocument()
        }
    }
}
