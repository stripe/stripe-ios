//
//  PaymentSheetLoader+Link.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/19/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension PaymentSheetLoader {
    @MainActor
    static func loadLink(
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        prefetchedEmailAndSourceTask: Task<(email: String, source: EmailSource)?, Never>,
        loadTimings: LoadTimings,
        isUpdate: Bool
    ) async -> (isLinkEnabled: Bool, didLinkLookupTimeOut: Bool?) {
        let isLinkEnabled = PaymentSheet.isLinkEnabled(
            elementsSession: elementsSession,
            configuration: configuration
        )
        let lookupLinkAccountTask = Task { @MainActor in
            let prefetchedLinkEmailAndSource = await prefetchedEmailAndSourceTask.value
            let linkAccount = try? await Self.lookupLinkAccount(
                elementsSession: elementsSession,
                configuration: configuration,
                prefetchedEmailAndSource: prefetchedLinkEmailAndSource,
                loadTimings: loadTimings,
                isUpdate: isUpdate
            )

            // We don't want to set the global singleton if we timed out, because that means setting it after MPE has finished loading, which the code is not necessarily expecting.
            guard !Task.isCancelled else { return }
            if isLinkEnabled {
                LinkAccountContext.shared.account = linkAccount
            }
            Self.logExperimentExposures(
                elementsSession: elementsSession,
                configuration: configuration,
                linkAccount: linkAccount,
                analyticsHelper: analyticsHelper
            )
        }

        // Only block on link lookup if it's enabled.
        var didLinkLookupTimeOut: Bool?
        if isLinkEnabled {
            let result = await withTimeout(5.0) {
                await lookupLinkAccountTask.value
            }
            switch result {
            case .success:
                didLinkLookupTimeOut = false
            case .failure(let error):
                if error is TimeoutError {
                    didLinkLookupTimeOut = true
                    // Since we're using unstructured Tasks, we have to manually cancel it.
                    lookupLinkAccountTask.cancel()
                }
            }
        }

        return (isLinkEnabled, didLinkLookupTimeOut)
    }

    @MainActor
    static func lookupLinkAccount(
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        prefetchedEmailAndSource: (email: String, source: EmailSource)?,
        loadTimings: LoadTimings,
        isUpdate: Bool
    ) async throws -> PaymentSheetLinkAccount? {
        // If we already have a verified Link account and the merchant is just calling `update` on FlowController or Embedded,
        // keep the account logged-in. Otherwise, the user has to verify via OTP again.
        if isUpdate, let currentLinkAccount = LinkAccountContext.shared.account, currentLinkAccount.sessionState == .verified {
            return currentLinkAccount
        }

        // Lookup Link account if Link is enabled, or if Link is disabled due to the holdback experiment (to collect experiment dimensions).
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)
        let isLinkInHoldbackExperiment = PaymentSheet.isLinkInHoldbackExperiment(elementsSession: elementsSession)
        let isLookupForHoldbackEnabled = elementsSession.flags["elements_disable_link_global_holdback_lookup"] != true

        guard isLinkEnabled || (isLinkInHoldbackExperiment && isLookupForHoldbackEnabled) else {
            return nil
        }
        loadTimings.logStart("lookUpLinkAccount")
        defer {
            loadTimings.logEnd("lookUpLinkAccount")
        }

        // Don't log this as a lookup on the backend side if Link is not enabled.
        // As in, this will be true when this lookup is only happening to gather dimensions for the holdback experiment.
        // Note: When the holdback experiment is over, we can remove this parameter from the lookup call.
        let doNotLogConsumerFunnelEvent = !isLinkEnabled

        // This lookup call will only happen if we have access to a user's email:
        // There are a couple different sources.
        let lookupEmail: (email: String, source: EmailSource)
        if let email = configuration.defaultBillingDetails.email {
            // 1. Merchant provided in `defaultBillingDetails`
            lookupEmail = (email, EmailSource.customerEmail)
        } else if let prefetchedEmailAndSource {
            // 2. We fetched the Customer object before calling this method to get its email when using EKs
            lookupEmail = prefetchedEmailAndSource
        } else if let email = elementsSession.customer?.email {
            // 3. The v1/e/s response returns the email when using CustomerSession
            lookupEmail = (email, EmailSource.customerObject)
        } else {
            return nil
        }

        let linkAccountService = LinkAccountService(apiClient: configuration.apiClient, elementsSession: elementsSession)
        let linkAccount = try await linkAccountService.lookupAccount(
            withEmail: lookupEmail.email,
            emailSource: lookupEmail.source,
            doNotLogConsumerFunnelEvent: doNotLogConsumerFunnelEvent
        )
        // PaymentSheet can be torn down and rebuilt while the customer is still using the same Link account.
        // Preserve the verified session across the second lookup so the user does not need to OTP again.
        if let currentLinkAccount = LinkAccountContext.shared.account {
            linkAccount?.reuseVerifiedSession(from: currentLinkAccount)
        }
        return linkAccount
    }

    @MainActor
    private static func logExperimentExposures(
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        linkAccount: PaymentSheetLinkAccount?,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) {
        Task {
            guard let arbId = elementsSession.experimentsData?.arbId else {
                return
            }
            analyticsHelper.logExposure(experiment: LinkGlobalHoldback(
                arbId: arbId,
                session: elementsSession,
                configuration: configuration,
                linkAccount: linkAccount,
                integrationShape: analyticsHelper.integrationShape
            ))
            analyticsHelper.logExposure(experiment: LinkGlobalHoldbackAA(
                arbId: arbId,
                session: elementsSession,
                configuration: configuration,
                linkAccount: linkAccount,
                integrationShape: analyticsHelper.integrationShape
            ))
            analyticsHelper.logExposure(experiment: LinkABTest(
                arbId: arbId,
                session: elementsSession,
                configuration: configuration,
                linkAccount: linkAccount,
                integrationShape: analyticsHelper.integrationShape
            ))
            analyticsHelper.logExposure(experiment: ConnectionsFCLiteVsNative(
                arbId: arbId,
                session: elementsSession
            ))
            analyticsHelper.logExposure(experiment: ConnectionsFCLiteVsNativeAA(
                arbId: arbId,
                session: elementsSession
            ))
        }
    }

    /// If configuration uses Ephemeral Key, retrieve Customer object and return email
    @MainActor
    static func getCustomerEmailForLinkWithEphemeralKey(
        configuration: PaymentElementConfiguration,
        loadTimings: LoadTimings
    ) async throws -> (email: String, source: EmailSource)? {
        guard
            configuration.defaultBillingDetails.email == nil, // If email was already provided, don't make a network request to retrieve it.
            let customerID = configuration.customer?.id,
            case .legacyCustomerEphemeralKey(let ephemeralKey) = configuration.customer?.customerAccessProvider
        else {
            return nil
        }
        loadTimings.logStart("retrieveCustomer")
        defer {
            loadTimings.logEnd("retrieveCustomer")
        }
        let customer = try await configuration.apiClient.retrieveCustomer(customerID, using: ephemeralKey)
        if let email = customer.email {
            return (email, EmailSource.customerObject)
        }
        return nil
    }
}
