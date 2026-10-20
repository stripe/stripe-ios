//
//  NetworkedIdentityFlowViewController+Strings.swift
//  StripeIdentity
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension NetworkedIdentityFlowViewController {
    enum Strings {
        static var continueButton: String {
            String.Localized.continue
        }

        static var manualCapture: String {
            STPLocalizedString(
                "Manually verify identity",
                "Button to verify identity with a new document instead of an ID saved to Link"
            )
        }

        static var documentsTitle: String {
            STPLocalizedString(
                "Choose a saved ID",
                "Title of the list of IDs saved to the user's Link account"
            )
        }

        static var documentsBody: String {
            STPLocalizedString(
                "Select an ID to continue.",
                "Instructions above the list of IDs saved to the user's Link account"
            )
        }

        static var documentsLoading: String {
            STPLocalizedString(
                "Loading your saved IDs…",
                "Status while loading the IDs saved to the user's Link account"
            )
        }

        static var share: String {
            STPLocalizedString(
                "Share ID",
                "Button to share the selected ID saved to Link with this verification"
            )
        }

        static var sharing: String {
            STPLocalizedString(
                "Sharing your ID…",
                "Status while sharing an ID saved to Link with this verification"
            )
        }

        static var sharedTitle: String {
            STPLocalizedString(
                "You shared your ID",
                "Title after the user shared an ID saved to Link with this verification"
            )
        }

        static var sharedBody: String {
            STPLocalizedString(
                "This ID will be used for your verification.",
                "Body text after the user shared an ID saved to Link with this verification"
            )
        }

        static var skipping: String {
            STPLocalizedString(
                "Continuing with manual verification…",
                "Status while continuing to verify identity with a new document instead of an ID saved to Link"
            )
        }

        static var saving: String {
            STPLocalizedString(
                "Saving your ID…",
                "Status while saving the user's ID to Link"
            )
        }

        static var continueWithLink: String {
            String.Localized.continue_with_link
        }

        @MainActor static var done: String {
            UIButton.doneButtonTitle
        }

        static var saveFailedTitle: String {
            STPLocalizedString(
                "Couldn't save your ID",
                "Title when saving the user's ID to Link failed"
            )
        }

        static var saveFailedBody: String {
            STPLocalizedString(
                "Something went wrong while saving your ID to Link. Your verification isn't affected.",
                "Body text when saving the user's ID to Link failed"
            )
        }

        static var close: String {
            String.Localized.close
        }

        static func savePreparedTitle(includesSelfie: Bool) -> String {
            includesSelfie
                ? STPLocalizedString(
                    "ID and selfie saved",
                    "Title after the user's ID and selfie were saved to Link"
                )
                : STPLocalizedString(
                    "ID saved",
                    "Title after the user's ID was saved to Link"
                )
        }

        static func savePreparedBody(includesSelfie: Bool) -> String {
            includesSelfie
                ? STPLocalizedString(
                    "They are encrypted and ready to reuse with your Link wallet.",
                    "Body text after the user's ID and selfie were saved to Link"
                )
                : STPLocalizedString(
                    "It's encrypted and ready to reuse with your Link wallet.",
                    "Body text after the user's ID was saved to Link"
                )
        }

        static func documentLabel(_ document: NetworkedIdentityDocument) -> String {
            let type: String
            switch document.documentType {
            case .drivingLicense:
                type = STPLocalizedString("Driver's license", "Type of an ID saved to Link")
            case .passport:
                type = STPLocalizedString("Passport", "Type of an ID saved to Link")
            case .idCard:
                type = STPLocalizedString("Identity card", "Type of an ID saved to Link")
            case .unparsable:
                type = STPLocalizedString("Identity document", "Type of an ID saved to Link that the app doesn't recognize")
            }
            guard let number = document.redactedDocumentNumber, !number.isEmpty else {
                return type
            }
            return "\(type) \(number)"
        }
    }
}
