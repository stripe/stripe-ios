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
        return STPLocalizedString("Learn more", "Represents the text of a button that can be clicked to learn more about some topic. Once clicked, a web-browser will be opened to give users more info.")
    }
}
