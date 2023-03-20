//
//  String+Localized.swift
//  StripeCardScan
//
//  Created by Sam King on 12/8/21.
//

import Foundation
@_spi(STP) import StripeCore

extension String.Localized {
    static var card_doesnt_match: String {
        return STPLocalizedString(
            "Card doesn't match",
            "Label of the error message when the scanned card mismatches the card on file"
        )
    }
    
    static var torch: String {
        return STPLocalizedString(
            "Torch",
            "Label for the button that toggles the camera's torch"
        )
    }
    
    static var enable_camera_access: String {
        return STPLocalizedString(
            "Enable camera access",
            "Label for button to take customer to camera settings"
        )
    }
    
    static var update_phone_settings: String {
        return STPLocalizedString(
            "To scan your card you'll need to update your phone settings",
            "Label to explain that they need to update phone settings to scan"
        )
    }
    
    static var enter_card_details_manually: String {
        return STPLocalizedString(
            "Enter card details manually",
            "Label for button to enter card details manually instead of scanning"
        )
    }
}
