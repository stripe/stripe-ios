//
//  NetworkedIdentitySaveViewController+Strings.swift
//  StripeIdentity
//

@_spi(STP) import StripeCore

extension NetworkedIdentitySaveViewController {
    enum Strings {
        static var title: String {
            STPLocalizedString(
                "Verify faster next time",
                "Title of the offer to save the user's ID to Link"
            )
        }

        static var encrypted: String {
            STPLocalizedString(
                "Link encrypts your saved information for your protection.",
                "Point in the offer to save the user's ID to Link"
            )
        }

        static var saveWith: String {
            STPLocalizedString(
                "Save with",
                "Button title followed by the Link logo, read as 'Save with Link'"
            )
        }

        static var saveWithLink: String {
            STPLocalizedString(
                "Save with Link",
                "Accessibility label of the button that saves the user's ID to Link"
            )
        }

        static var finishWithoutSaving: String {
            STPLocalizedString(
                "Finish without saving",
                "Button to finish the verification without saving the user's ID to Link"
            )
        }

        static func subtitle(includesSelfie: Bool) -> String {
            includesSelfie
                ? STPLocalizedString(
                    "Save your ID and selfie with Link.",
                    "Subtitle of the offer to save the user's ID and selfie to Link"
                )
                : STPLocalizedString(
                    "Save your ID with Link.",
                    "Subtitle of the offer to save the user's ID to Link"
                )
        }

        static func reuse(includesSelfie: Bool) -> String {
            includesSelfie
                ? STPLocalizedString(
                    "Save your ID and selfie for the next time you need to verify.",
                    "Point in the offer to save the user's ID and selfie to Link"
                )
                : STPLocalizedString(
                    "Save your ID for the next time you need to verify.",
                    "Point in the offer to save the user's ID to Link"
                )
        }
    }
}
