//
//  String+Localized.swift
//  StripeCore
//
//  Created by Mel Ludowise on 8/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) extension String {
    public enum Localized {
        public static var close: String {
            return STPLocalizedString("7d9eb", "Text for close button")
        }

        public static var tryAgain: String {
            return STPLocalizedString("d8b83", "Text for a retry button")
        }

        public static var scan_card_title_capitalization: String {
            STPLocalizedString("b60b5", "Text for button to scan a credit card")
        }

        public static var scan_card: String {
            STPLocalizedString("ea2fe", "Button title to open camera to scan credit/debit card")
        }

        public static var scan_card_privacy_link_text: String {
            // THIS STRING SHOULD NOT BE MODIFIED
            STPLocalizedString(
                "96fe7",
                "Informational text informing the user that Stripe is used to process data and a link to Stripe's privacy policy"
            )
        }

        public static func scanCardExpectedPrivacyLinkText() -> NSAttributedString? {
            let stringData = Data(String.Localized.scan_card_privacy_link_text.utf8)
            let stringOptions: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ]

            return try? NSAttributedString(
                data: stringData,
                options: stringOptions,
                documentAttributes: nil
            )
        }
    }
}
