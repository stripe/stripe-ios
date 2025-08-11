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
                return STPLocalizedString(
                    "Front of identity document",
                    "Title of ID document scanning screen when scanning the front of an identity card"
                )
            } else {
                return STPLocalizedString(
                    "Back of identity document",
                    "Title of ID document scanning screen when scanning the back of an identity card"
                )
            }
        }

        // Convert ID types to localized strings
        let localizedTypes = availableIDTypes.compactMap { $0.uiIDType() }

        // Handle specific combinations
        if localizedTypes.count == 2 {
            if localizedTypes.contains(String.Localized.driverLicense) && localizedTypes.contains(String.Localized.passport) {
                return self == .front ? String.Localized.frontOfDriverLicenseOrPassport : String.Localized.backOfDriverLicenseOrPassport
            } else if localizedTypes.contains(String.Localized.driverLicense) && localizedTypes.contains(String.Localized.governmentIssuedId) {
                return self == .front ? String.Localized.frontOfDriverLicenseOrGovernmentId : String.Localized.backOfDriverLicenseOrGovernmentId
            } else if localizedTypes.contains(String.Localized.passport) && localizedTypes.contains(String.Localized.governmentIssuedId) {
                return self == .front ? String.Localized.frontOfPassportOrGovernmentId : String.Localized.backOfPassportOrGovernmentId
            } else {
                // Fallback to generic text
                return idDocument()
            }
        } else if localizedTypes.count == 3 {
            // Handle all three types
            return self == .front ? String.Localized.frontOfAllIdTypes : String.Localized.backOfAllIdTypes
        } else if localizedTypes.count == 1, let type = localizedTypes.first {
            // Handle single type
            switch self {
            case .front:
                return String(format: STPLocalizedString("Front of %@", "Title of ID document scanning screen when scanning the front of either a driver's license, passport, or government issued photo id "), type)
            case .back:
                return String(format: STPLocalizedString("Back of %@", "Title of ID document scanning screen when scanning the back of either a driver's license, passport, or government issued photo id"), type)
            }
        } else {
            // Fallback to generic text
            return idDocument()
        }
    }
}
