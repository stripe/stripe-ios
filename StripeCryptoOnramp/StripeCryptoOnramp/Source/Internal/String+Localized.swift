//
//  String+Localized.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/14/25.
//

import Foundation

extension String {
    static var Localized: LocaizedStrings.Type {
        return LocaizedStrings.self
    }
}

enum LocaizedStrings {
    static var debitIsMostLikelyToBeAccepted: String {
        return STPLocalizedString(
            "Debit is most likely to be accepted.",
            "Label shown in the Link UI indicating that debit cards are more likely to be accepted"
        )
    }
}
