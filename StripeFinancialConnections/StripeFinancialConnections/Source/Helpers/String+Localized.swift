//
//  String+Localized.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/22/22.
//

import Foundation
@_spi(STP) import StripeCore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
// We use snake case to make long names easier to read.
extension String.Localized {
    static func continue_with_link(brand: LinkBrand) -> String {
        return String(
            format: STPLocalizedString(
                "Continue with %@",
                "A button title. The placeholder is a Stripe brand name and should not be translated."
            ),
            brand.displayName
        )
    }

    static func use_information_you_previously_saved_with_your_brand_account(brand: LinkBrand) -> String {
        return String(
            format: STPLocalizedString(
                "Use information you previously saved with your %@ account.",
                "The subtitle/description of a screen where users are informed that they can sign in to the Link brand. The placeholder is a Stripe brand name and should not be translated."
            ),
            brand.displayName
        )
    }

    static func your_account_was_connected_but_could_not_be_saved_to_brand(brand: LinkBrand) -> String {
        return String(
            format: STPLocalizedString(
                "Your account was connected, but couldn't be saved to %@.",
                "The subtitle/description of the success screen when the user's single connected account could not be saved to the Link brand. The placeholder is a Stripe brand name and should not be translated."
            ),
            brand.displayName
        )
    }

    static func your_accounts_were_connected_but_could_not_be_saved_to_brand(brand: LinkBrand) -> String {
        return String(
            format: STPLocalizedString(
                "Your accounts were connected, but couldn't be saved to %@.",
                "The subtitle/description of the success screen when the user's connected accounts could not be saved to the Link brand. The placeholder is a Stripe brand name and should not be translated."
            ),
            brand.displayName
        )
    }

    static var learn_more: String {
        return STPLocalizedString(
            "Learn more",
            "Represents the text of a button that can be clicked to learn more about some topic. Once clicked, a web-browser will be opened to give users more info."
        )
    }

    static var select_another_bank: String {
        return STPLocalizedString(
            "Select another bank",
            "The title of a button. The button presents the user an option to select another bank. For example, we may show this button after user failed to link their primary bank, but maybe the user can try to link their secondary bank!"
        )
    }

    static var enter_bank_details_manually: String {
        return STPLocalizedString(
            "Enter bank details manually",
            "The title of a button. The button presents the user an option to enter their bank details (account number, routing number) manually. For example, we may show this button after user failed to link their bank 'automatically' with Stripe, so we offer them the option manually link it."
        )
    }
}
