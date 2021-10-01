//
//  String+Localized.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/16/21.
//

import Foundation
@_spi(STP) import StripeCore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
// We use snake case to make long names easier to read.
@_spi(STP) public extension String.Localized {

    static var address_line1: String {
        STPLocalizedString("Address line 1", "Address line 1 placeholder for billing address form.\nLabel for address line 1 field")
    }

    static var address_line2: String {
        STPLocalizedString("Address line 2", "Label for address line 2 field")
    }

    static var country_or_region: String {
        STPLocalizedString("Country or region", "Country selector and postal code entry form header title\nLabel of an address field")
    }

    static var country: String {
        STPLocalizedString("Country", "Caption for Country field on address form")
    }
    
    static var email: String {
        STPLocalizedString("Email", "Label for Email field on form")
    }

    static var name: String {
        STPLocalizedString("Name", "Label for Name field on form")
    }

    static var invalid_email: String {
        STPLocalizedString("Your email is invalid.", "Error message when email is invalid")
    }

    static var optional_field: String {
        STPLocalizedString(
            "%@ (optional)",
            "The label of a text field that is optional. For example, 'Email (optional)' or 'Name (optional)"
        )
    }
}
