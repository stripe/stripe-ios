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
    @_spi(STP) public static func continue_with_link(brand _: LinkBrand) -> String {
        STPLocalizedString(
            "Continue with Link",
            """
            A button title. This button, when pressed, will automatically log-in the user with their e-mail to Link (one-click checkout provider).
               The title of a screen where users are informed that they can sign-in-to Link.
            """
        )
    }

    @_spi(STP) public static func use_information_you_previously_saved_with_your_brand_account(brand _: LinkBrand) -> String {
        STPLocalizedString(
            "Use information you previously saved with your Link account.",
            "The subtitle/description of a screen where users are informed that they can sign-in-to Link."
        )
    }

    @_spi(STP) public static func your_account_was_connected_but_could_not_be_saved_to_brand(brand _: LinkBrand) -> String {
        STPLocalizedString(
            "Your account was connected, but couldn't be saved to Link.",
            "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank account to an application. Now that the bank account is connected, the user will be able to use the bank account for payments."
        )
    }

    @_spi(STP) public static func your_accounts_were_connected_but_could_not_be_saved_to_brand(brand _: LinkBrand) -> String {
        STPLocalizedString(
            "Your accounts were connected, but couldn't be saved to Link.",
            "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank account to an application. Now that the bank account is connected, the user will be able to use the bank account for payments."
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
