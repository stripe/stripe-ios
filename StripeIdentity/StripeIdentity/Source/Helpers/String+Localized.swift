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
    static var error: String {
        return STPLocalizedString(
            "Error",
            "Text for error labels"
        )
    }

    static var loading: String {
        return STPLocalizedString("Loading", "Status while screen is loading")
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

    static var select: String {
        STPLocalizedString(
            "Select",
            "Button to select a file to upload"
        )
    }
}
