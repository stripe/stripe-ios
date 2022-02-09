//
//  String+Localized.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 9/27/21.
//

import Foundation
@_spi(STP) import StripeCore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
// We use snake case to make long names easier to read.
extension String.Localized {

    // MARK: - Document Type Selection

    static var passport: String {
        return STPLocalizedString(
            "Passport",
            "Label of the passport option for document type selection"
        )
    }

    static var driving_license: String {
        return STPLocalizedString(
            "Driver's license",
            "Label of the driver's license option for document type selection"
        )
    }

    static var id_card: String {
        return STPLocalizedString(
            "Identity card",
            "Label of the ID Card option for document type selection"
        )
    }

    // MARK: - Additional Info fields

    static var date_of_birth: String {
        STPLocalizedString(
            "Date of birth",
            "Label for Date of birth field"
        )
    }

    static var id_number_title: String {
        STPLocalizedString(
            "ID Number",
            "Label for ID number section"
        )
    }

    static var personal_id_number: String {
        STPLocalizedString(
            "Personal ID number",
            "Label for the personal id number field in the hosted verification details collection form for countries without an exception"
        )
    }

    // MARK: - Document Upload

    static var app_settings: String {
        STPLocalizedString(
            "App Settings",
            "Opens the app's settings in the Settings app"
        )
    }
}
