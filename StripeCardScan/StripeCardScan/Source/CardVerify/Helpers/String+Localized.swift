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
        return STPLocalizedString("3c701",
            "Label of the error message when the scanned card mismatches the card on file"
        )
    }

    static var torch: String {
        return STPLocalizedString("dcc57",
            "Label for the button that toggles the camera's torch"
        )
    }

    static var enable_camera_access: String {
        return STPLocalizedString("22df6",
            "Label for button to take customer to camera settings"
        )
    }

    static var update_phone_settings: String {
        return STPLocalizedString("6fa8c",
            "Label to explain that they need to update phone settings to scan"
        )
    }

    static var enter_card_details_manually: String {
        return STPLocalizedString("3fde0",
            "Label for button to enter card details manually instead of scanning"
        )
    }
}
