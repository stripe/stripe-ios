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
