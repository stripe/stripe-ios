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
            return STPLocalizedString("Close", "Text for close button")
        }

        public static var tryAgain: String {
            return STPLocalizedString("Try again", "Text for a retry button")
        }

        public static var scan_card_title_capitalization: String {
            STPLocalizedString("Scan Card", "Text for button to scan a credit card")
        }

        public static var scan_card: String {
            STPLocalizedString("Scan card", "Button title to open camera to scan credit/debit card")
        }

        public static var scan_card_privacy_link_text: String {
            // THIS STRING SHOULD NOT BE MODIFIED
            STPLocalizedString(
                "We use Stripe to verify your card details. Stripe may use and store your data according its privacy policy. <a href='https://support.stripe.com/questions/stripes-card-image-verification'><u>Learn more</u></a>",
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
