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
    private static func existingLinkLocalizedString(_ key: String) -> String {
        STPLocalizationUtils.localizedStripeString(
            forKey: key,
            bundleLocator: StripeFinancialConnectionsBundleLocator.self
        )
    }

    @_spi(STP) public static func continue_with_link(brand _: LinkBrand) -> String {
        existingLinkLocalizedString("Continue with Link")
    }

    @_spi(STP) public static func use_information_you_previously_saved_with_your_brand_account(brand _: LinkBrand) -> String {
        existingLinkLocalizedString("Use information you previously saved with your Link account.")
    }

    @_spi(STP) public static func your_account_was_connected_but_could_not_be_saved_to_brand(brand _: LinkBrand) -> String {
        existingLinkLocalizedString("Your account was connected, but couldn't be saved to Link.")
    }

    @_spi(STP) public static func your_accounts_were_connected_but_could_not_be_saved_to_brand(brand _: LinkBrand) -> String {
        existingLinkLocalizedString("Your accounts were connected, but couldn't be saved to Link.")
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
