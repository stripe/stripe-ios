//
//  LinkBillingDetailsValidator.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 8/5/25.
//

import Foundation
@_spi(STP) import StripePayments

class LinkBillingDetailsValidator {

    enum ValidationResult {
        case complete(updatedPaymentDetails: ConsumerPaymentDetails, confirmationExtras: LinkConfirmationExtras)
        case incomplete(partialPaymentDetails: ConsumerPaymentDetails)
    }

    private let linkAccount: PaymentSheetLinkAccount
    private let context: PayWithLinkViewController.Context

    init(
        linkAccount: PaymentSheetLinkAccount,
        context: PayWithLinkViewController.Context
    ) {
        self.linkAccount = linkAccount
        self.context = context
    }

    /// Validates that the `ConsumerPaymentDetails` has all required billing details. If not, it will attempt to fill in the missing details. If this is not possible,
    /// it returns an `.incomplete` result with with partially filled billing details.
    func validate(
        _ consumerPaymentDetails: ConsumerPaymentDetails
    ) async -> ValidationResult {
        guard isMissingRequestedBillingDetails(consumerPaymentDetails) else {
            // No additional billing details to collect.
            let confirmationExtras = LinkConfirmationExtras(billingPhoneNumber: nil)
            return .complete(updatedPaymentDetails: consumerPaymentDetails, confirmationExtras: confirmationExtras)
        }

        // Fill in missing fields with default values from the provided billing details and
        // from the Link account.
        let effectiveBillingDetails = context.configuration.effectiveBillingDetails(for: linkAccount)

        let effectivePaymentDetails = consumerPaymentDetails.update(
            with: effectiveBillingDetails,
            basedOn: context.configuration.billingDetailsCollectionConfiguration
        )

        let hasRequiredBillingDetailsNow = effectivePaymentDetails.supports(
            context.configuration.billingDetailsCollectionConfiguration,
            in: linkAccount.currentSession
        )

        if hasRequiredBillingDetailsNow {
            // We have filled in all the missing fields. Now, update the payment details and confirm the intent.
            do {
                let updatedPaymentDetails = try await updateBillingDetails(
                    paymentDetailsID: consumerPaymentDetails.stripeID,
                    billingAddress: effectivePaymentDetails.billingAddress,
                    billingEmailAddress: effectiveBillingDetails.email
                )

                // We need to pass the billing phone number explicitly, since it's not part of the billing details.
                let confirmationExtras = LinkConfirmationExtras(
                    billingPhoneNumber: effectiveBillingDetails.phone
                )

                return .complete(updatedPaymentDetails: updatedPaymentDetails, confirmationExtras: confirmationExtras)
            } catch {
                return .incomplete(partialPaymentDetails: effectivePaymentDetails)
            }
        } else {
            // We're still missing fields. Prompt the user to fill them in.
            return .incomplete(partialPaymentDetails: effectivePaymentDetails)
        }
    }

    private func isMissingRequestedBillingDetails(_ paymentDetails: ConsumerPaymentDetails) -> Bool {
        guard context.configuration.link.collectMissingBillingDetailsForExistingPaymentMethods else {
            // Don't recollect even if details are missing
            return false
        }

        let paymentDetailsAreSupported = paymentDetails.supports(
            context.configuration.billingDetailsCollectionConfiguration,
            in: linkAccount.currentSession
        )

        return !paymentDetailsAreSupported
    }

    private func updateBillingDetails(
        paymentDetailsID: String,
        billingAddress: BillingAddress?,
        billingEmailAddress: String?
    ) async throws -> ConsumerPaymentDetails {
        let billingDetails = STPPaymentMethodBillingDetails(
            billingAddress: billingAddress,
            email: billingEmailAddress
        )

        let updateParams = UpdatePaymentDetailsParams(
            details: .card(billingDetails: billingDetails)
        )

        let clientAttributionMetadata = STPClientAttributionMetadata.makeClientAttributionMetadataIfNecessary(analyticsHelper: context.analyticsHelper, intent: context.intent, elementsSession: context.elementsSession)

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.linkAccount.updatePaymentDetails(
                id: paymentDetailsID,
                updateParams: updateParams,
                clientAttributionMetadata: clientAttributionMetadata
            ) { result in
                switch result {
                case .success(let updatedPaymentDetails):
                    continuation.resume(returning: updatedPaymentDetails)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
