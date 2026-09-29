//
//  String+Localized.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/14/25.
//

import Foundation
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension String.Localized {
    static var cryptoOnrampErrorAppAttestationUnavailable: String {
        return STPLocalizedString(
            "This app couldn't be verified. Contact the app developer for help.",
            "Error message shown when app attestation is not configured for crypto onramp"
        )
    }

    static var cryptoOnrampErrorAppAttestationFailed: String {
        return STPLocalizedString(
            "This app couldn't be verified due to an attestation error. Please try again later or contact the developer if the issue persists.",
            "Error message shown when app attestation fails"
        )
    }

    static var cryptoOnrampErrorInvalidWalletOwnershipSignature: String {
        return STPLocalizedString(
            "We couldn't verify ownership of this wallet. Please try again.",
            "Error message shown when the submitted wallet ownership signature is invalid"
        )
    }

    static var cryptoOnrampErrorWalletOwnershipChallengeExpired: String {
        return STPLocalizedString(
            "This wallet verification request expired. Please try again.",
            "Error message shown when the wallet ownership challenge has expired"
        )
    }

    static var cryptoOnrampErrorInvalidWalletOwnershipChallenge: String {
        return STPLocalizedString(
            "This wallet verification request is invalid. Please try again.",
            "Error message shown when the wallet ownership challenge is invalid"
        )
    }

    static var cryptoOnrampErrorWalletNotFound: String {
        return STPLocalizedString(
            "This wallet couldn't be found. Please choose or add a wallet and try again.",
            "Error message shown when the wallet is not registered for crypto onramp"
        )
    }

    static var cryptoOnrampErrorUnsupportedNetwork: String {
        return STPLocalizedString(
            "This wallet network isn't supported. Please choose a different network.",
            "Error message shown when the wallet network is not supported for crypto onramp"
        )
    }

    static var debitIsMostLikelyToBeAccepted: String {
        return STPLocalizedString(
            "Debit cards are most likely to be accepted.",
            "Label shown in the Link UI indicating that debit cards are more likely to be accepted"
        )
    }

    static var uploadProofOfAddress: String {
        STPLocalizedString("Upload your proof of address", "Heading introducing proof of address collection")
    }

    static var proofOfAddressExplanation: String {
        STPLocalizedString(
            "We may request proof of address for larger transactions.",
            "Explanation introducing proof of address collection."
        )
    }

    static var tellUsAboutYourSourceOfFunds: String {
        STPLocalizedString("Tell us about your source of funds", "Heading introducing source of funds collection")
    }

    static var sourceOfFundsExplanation: String {
        STPLocalizedString(
            "We may request source of funds for larger transactions.",
            "Explanation introducing source of funds collection."
        )
    }

    /// The label and placeholder for a questionnaire answer field.
    static var questionnaireAnswer: String {
        STPLocalizedString("Answer", "Label and placeholder for a questionnaire answer field")
    }

    static var documentType: String {
        STPLocalizedString("Document type", "Label and picker title for a document's category")
    }

    static var uploadDocument: String {
        STPLocalizedString("Upload document", "Action to select an existing document for upload")
    }

    /// The action that opens document collection for a new funds source.
    static var addDocuments: String {
        STPLocalizedString("Add documents", "Action to add documents for another source of funds")
    }

    /// The status shown while a document is uploading.
    static var uploadingDocument: String {
        STPLocalizedString("Uploading…", "Status while a document is uploading")
    }

    /// The status shown after a document uploads successfully.
    static var documentUploaded: String {
        STPLocalizedString("Uploaded", "Status after a document has uploaded successfully")
    }

    static var documentUploadedSuccessfully: String {
        STPLocalizedString("Document uploaded successfully", "Heading confirming a document was uploaded successfully")
    }

    static var documentVerificationInBackground: String {
        STPLocalizedString(
            "You can continue while we verify your document in the background.",
            "Message confirming the document was uploaded and the user can continue while verification happens in the background."
        )
    }

    static var submittedForReview: String {
        STPLocalizedString("Submitted for review", "Heading confirming documents were submitted for review")
    }

    static var documentsUnderReview: String {
        STPLocalizedString(
            "We’re reviewing your documents. We’ll let you know when verification is complete.",
            "Message confirming documents are being reviewed and the user will be notified when verification is complete."
        )
    }

    static var tryAgainLater: String {
        STPLocalizedString("Please try again later.", "Instruction after an unavailable operation")
    }

    static func redactedCardDetails(using card: StripeAPI.PaymentMethod.Card) -> String? {
        let brand = stpCardBrand(from: card.brand)
        let brandString = STPCard.string(from: brand)
        guard !brandString.isEmpty, let last4 = card.last4 else {
            return nil
        }

        return String(format: card_details_xxxx, brandString, last4)
    }

    private static func stpCardBrand(from brand: StripeAPI.PaymentMethod.Card.Brand) -> STPCardBrand {
        switch brand {
        case .visa: return .visa
        case .amex: return .amex
        case .mastercard: return .mastercard
        case .discover: return .discover
        case .jcb: return .JCB
        case .diners: return .dinersClub
        case .unionpay: return .unionPay
        case .unknown, .unparsable: return .unknown
        }
    }
}
