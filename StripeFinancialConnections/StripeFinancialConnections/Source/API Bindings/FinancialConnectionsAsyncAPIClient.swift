//
//  FinancialConnectionsAsyncAPIClient.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-01-07.
//

import Foundation
@_spi(STP) import StripeCore

final class FinancialConnectionsAsyncAPIClient {
    private enum EncodingError: Error {
        case cannotCastToDictionary
    }

    enum PollingError: Error {
        case maxRetriesReached
    }

    enum EmailSource: String {
        case userAction = "user_action"
        case customerObject = "customer_object"
    }

    let backingAPIClient: STPAPIClient

    var isLinkWithStripe: Bool = false
    var consumerPublishableKey: String?
    var consumerSession: ConsumerSessionData?

    private lazy var logger = FinancialConnectionsAPIClientLogger()

    var requestSurface: String {
        isLinkWithStripe ? "ios_instant_debits" : "ios_connections"
    }

    init(apiClient: STPAPIClient) {
        self.backingAPIClient = apiClient
    }

    /// Returns the `consumerPublishableKey` for scenarios where it is valid to do so. That is;
    /// - `canUseConsumerKey` must be `true`. This is a flag passed in by each API request.
    /// - `isLinkWithStripe` must be `true`. This represents whether we're in the Instant Debits flow.
    /// - `consumerSession` must be verified. This represents whether we have a verified Link user.
    func consumerPublishableKeyProvider(canUseConsumerKey: Bool) -> String? {
        guard canUseConsumerKey, isLinkWithStripe, consumerSession?.isVerified == true else {
            return nil
        }
        return consumerPublishableKey
    }

    /// Marks the assertion as completed and forwards attestation errors to the `StripeAttest` client for logging.
    /// If any attestation errors are present, return them synchronously while completing the assertion.
    func completeAssertion(
        possibleError: Error?,
        api: FinancialConnectionsAPIClientLogger.API,
        pane: FinancialConnectionsSessionManifest.NextPane
    ) -> Error? {
        let attest = backingAPIClient.stripeAttest
        let attestationError: Error?
        if let error = possibleError, StripeAttest.isLinkAssertionError(error: error) {
            attestationError = error
        } else {
            attestationError = nil
        }
        Task { @Sendable in
            if let attestationError {
                logger.log(.attestationVerdictFailed(api), pane: pane)
                await attest.receivedAssertionError(attestationError)
            }
            await attest.assertionCompleted()
        }
        return attestationError
    }

    /// Applies attestation-related parameters to the given base parameters
    /// In case of an assertion error, returns the unmodified base parameters
    func assertAndApplyAttestationParameters(
        to baseParameters: [String: Any],
        api: FinancialConnectionsAPIClientLogger.API,
        pane: FinancialConnectionsSessionManifest.NextPane
    ) async -> [String: Any] {
        do {
            let attest = backingAPIClient.stripeAttest
            let handle = try await attest.assert()
            logger.log(.attestationRequestTokenSucceeded(api), pane: pane)
            let newParameters = baseParameters.merging(handle.assertion.requestFields) { (_, new) in new }
            return newParameters
        } catch {
            // Fail silently if we can't get an assertion, we'll try the request anyway. It may fail.
            logger.log(.attestationRequestTokenFailed(api, error), pane: pane)
            return baseParameters
        }
    }

    /// Passthrough to `STPAPIClient.get` which uses the `consumerPublishableKey` whenever it should be used.
    private func get<T: Decodable>(
        endpoint: FinancialConnectionsAPIEndpoint,
        parameters: [String: Any]
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let possibleConsumerPublishableKey = consumerPublishableKeyProvider(
                canUseConsumerKey: endpoint.shouldUseConsumerPublishableKey
            )
            backingAPIClient.get(
                resource: endpoint.rawValue,
                parameters: parameters,
                consumerPublishableKey: possibleConsumerPublishableKey,
                completion: { (result: Result<T, Error>) in
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }

    /// Passthrough to `STPAPIClient.post` which uses the `consumerPublishableKey` whenever it should be used.
    private func post<T: Decodable>(
        endpoint: FinancialConnectionsAPIEndpoint,
        parameters: [String: Any]
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let possibleConsumerPublishableKey = consumerPublishableKeyProvider(
                canUseConsumerKey: endpoint.shouldUseConsumerPublishableKey
            )
            backingAPIClient.post(
                resource: endpoint.rawValue,
                parameters: parameters,
                consumerPublishableKey: possibleConsumerPublishableKey,
                completion: { (result: Result<T, Error>) in
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }

    func poll<T>(
        initialPollDelay: TimeInterval = 1.75,
        maxNumberOfRetries: Int = 180,
        retryInterval: TimeInterval = 0.25,
        // Inject the sleep action to avoid sleeping in unit tests.
        sleepAction: @escaping (UInt64) async throws -> Void = {
            try await Task.sleep(nanoseconds: $0)
        },
        apiCall: @escaping () async throws -> T
    ) async throws -> T {
        // Wait for the initial poll delay
        try await sleepAction(UInt64(initialPollDelay * 1_000_000_000))

        for attempt in 0..<maxNumberOfRetries {
            do {
                return try await apiCall()
            } catch {
                if attempt == maxNumberOfRetries - 1 {
                    throw PollingError.maxRetriesReached
                }
                // Wait for the retry interval before the next attempt
                try await sleepAction(UInt64(retryInterval * 1_000_000_000))
            }
        }

        throw PollingError.maxRetriesReached
    }

    private func updateAndApplyFraudDetection(
        to parameters: [String: Any]
    ) async -> [String: Any] {
        await withCheckedContinuation { continuation in
            STPTelemetryClient.shared.updateFraudDetectionIfNecessary { _ in
                // Fire and forget operation. Ignore any possible errors here.
                var paramsWithTelemetry = parameters
                paramsWithTelemetry = STPTelemetryClient.shared.paramsByAddingTelemetryFields(toParams: paramsWithTelemetry)
                continuation.resume(returning: paramsWithTelemetry)
            }
        }
    }

    static func encodeAsParameters(_ value: any Encodable) throws -> [String: Any]? {
        let jsonData = try JSONEncoder().encode(value)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)

        if let dictionary = jsonObject as? [String: Any] {
            return dictionary.isEmpty ? nil : dictionary
        } else {
            throw EncodingError.cannotCastToDictionary
        }
    }
}

extension FinancialConnectionsAsyncAPIClient {
    func synchronize(
        clientSecret: String,
        returnURL: String?,
        initialSynchronize: Bool = false
    ) async throws -> FinancialConnectionsSynchronize {
        var parameters: [String: Any] = [
            "expand": ["manifest.active_auth_session"],
            "client_secret": clientSecret,
            "locale": Locale.current.toLanguageTag(),
        ]

        var mobileParameters: [String: Any] = [
            "fullscreen": true,
            "hide_close_button": true,
            "forced_authflow_version": "v3",
        ]
        mobileParameters["app_return_url"] = returnURL

        if initialSynchronize {
            let attestationIsSupported = backingAPIClient.stripeAttest.isSupported
            mobileParameters["supports_app_verification"] = attestationIsSupported
            mobileParameters["verified_app_id"] = Bundle.main.bundleIdentifier
            if !attestationIsSupported {
                logger.log(.attestationInitFailed, pane: .consent)
            }
        }

        parameters["mobile"] = mobileParameters
        return try await post(endpoint: .synchronize, parameters: parameters)
    }

    func fetchFinancialConnectionsAccounts(
        clientSecret: String,
        startingAfterAccountId: String?
    ) async throws -> StripeAPI.FinancialConnectionsSession.AccountList {
        var parameters = ["client_secret": clientSecret]
        if let startingAfterAccountId = startingAfterAccountId {
            parameters["starting_after"] = startingAfterAccountId
        }
        return try await get(endpoint: .listAccounts, parameters: parameters)
    }

    func fetchFinancialConnectionsSession(clientSecret: String) async throws -> StripeAPI.FinancialConnectionsSession {
        try await get(
            endpoint: .sessionReceipt,
            parameters: ["client_secret": clientSecret]
        )
    }

    func markConsentAcquired(clientSecret: String) async throws -> FinancialConnectionsSessionManifest {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "expand": ["active_auth_session"],
        ]
        return try await post(endpoint: .consentAcquired, parameters: parameters)
    }

    func fetchFeaturedInstitutions(clientSecret: String) async throws -> FinancialConnectionsInstitutionList {
        try await get(
            endpoint: .featuredInstitutions,
            parameters: ["client_secret": clientSecret]
        )
    }

    func fetchInstitutions(clientSecret: String, query: String) async throws -> FinancialConnectionsInstitutionSearchResultResource {
        let parameters = [
            "client_secret": clientSecret,
            "query": query,
            "limit": "20",
        ]
        return try await get(endpoint: .searchInstitutions, parameters: parameters)
    }

    func createAuthSession(clientSecret: String, institutionId: String) async throws -> FinancialConnectionsAuthSession {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "institution": institutionId,
            "use_mobile_handoff": "false",
            "use_abstract_flow": true,
            "return_url": "ios",
        ]
        return try await post(endpoint: .authSessions, parameters: parameters)
    }

    func selectInstitution(clientSecret: String, institutionId: String) async throws -> FinancialConnectionsSelectInstitution {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "currently_selected_institution": institutionId,
        ]
        return try await post(endpoint: .selectInstitution, parameters: parameters)
    }

    func repairAuthSession(clientSecret: String, coreAuthorization: String) async throws -> FinancialConnectionsRepairSession {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "core_authorization": coreAuthorization,
            "return_url": "ios",
        ]
        return try await post(endpoint: .authSessions, parameters: parameters)
    }

    func cancelAuthSession(clientSecret: String, authSessionId: String) async throws -> FinancialConnectionsAuthSession {
        let parameters = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]
        return try await post(endpoint: .authSessionsCancel, parameters: parameters)
    }

    func retrieveAuthSession(
        clientSecret: String,
        authSessionId: String
    ) async throws -> FinancialConnectionsAuthSession {
        let parameters = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]
        return try await post(endpoint: .authSessionsRetrieve, parameters: parameters)
    }

    func retrieveAuthSessionPolling(
        clientSecret: String,
        authSessionId: String
    ) async throws -> FinancialConnectionsAuthSession {
        let parameters = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]
        return try await poll(
            initialPollDelay: 0,
            maxNumberOfRetries: 360, // Stripe.js has 360 retries and 500ms intervals
            retryInterval: 0.5
        ) { [weak self] in
            guard let self else {
                throw FinancialConnectionsSheetError.unknown(debugDescription: "FinancialConnectionsAsyncAPIClient deallocated.")
            }
            return try await self.post(endpoint: .authSessionsRetrieve, parameters: parameters)
        }
    }

    func fetchAuthSessionOAuthResults(clientSecret: String, authSessionId: String) async throws -> FinancialConnectionsMixedOAuthParams {
        let parameters = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]

        return try await poll(
            initialPollDelay: 0,
            maxNumberOfRetries: 300, // Stripe.js has 600 second timeout, 600 / 2 = 300 retries
            retryInterval: 2.0
        ) { [weak self] in
            guard let self else {
                throw FinancialConnectionsSheetError.unknown(debugDescription: "FinancialConnectionsAsyncAPIClient deallocated.")
            }
            return try await self.post(endpoint: .authSessionsOAuthResults, parameters: parameters)
        }
    }

    func authorizeAuthSession(
        clientSecret: String,
        authSessionId: String,
        publicToken: String?
    ) async throws -> FinancialConnectionsAuthSession {
        var parameters = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]
        parameters["public_token"] = publicToken  // not all integrations require public_token
        return try await post(endpoint: .authSessionsAuthorized, parameters: parameters)
    }

    func fetchAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        initialPollDelay: TimeInterval
    ) async throws -> FinancialConnectionsAuthSessionAccounts {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "id": authSessionId,
            "expand": ["data.institution"],
        ]
        return try await poll(
            initialPollDelay: initialPollDelay
        ) { [weak self] in
            guard let self else {
                throw FinancialConnectionsSheetError.unknown(debugDescription: "FinancialConnectionsAsyncAPIClient deallocated.")
            }
            return try await self.post(endpoint: .authSessionsAccounts, parameters: parameters)
        }
    }

    func selectAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        selectedAccountIds: [String]
    ) async throws -> FinancialConnectionsAuthSessionAccounts {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "id": authSessionId,
            "selected_accounts": selectedAccountIds,
            "expand": ["data.institution"],
        ]
        return try await post(endpoint: .authSessionsSelectedAccounts, parameters: parameters)
    }

    func markLinkingMoreAccounts(clientSecret: String) async throws -> FinancialConnectionsSessionManifest {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "expand": ["active_auth_session"],
        ]
        return try await post(endpoint: .linkMoreAccounts, parameters: parameters)
    }

    func completeFinancialConnectionsSession(
        clientSecret: String,
        terminalError: String?
    ) async throws -> StripeAPI.FinancialConnectionsSession {
        var parameters: [String: Any] = [
            "client_secret": clientSecret,
        ]
        parameters["terminal_error"] = terminalError

        let session: StripeAPI.FinancialConnectionsSession = try await post(endpoint: .complete, parameters: parameters)

        if session.accounts.hasMore {
            // de-paginate the accounts we get from the session because
            // we want to give the clients a full picture of the number
            // of accounts that were linked
            let accounts = try await fetchAccounts(clientSecret: clientSecret, resultsSoFar: session.accounts.data)
            return StripeAPI.FinancialConnectionsSession(
                clientSecret: clientSecret,
                id: session.id,
                accounts: StripeAPI.FinancialConnectionsSession.AccountList(
                    data: accounts,
                    hasMore: false
                ),
                livemode: session.livemode,
                paymentAccount: session.paymentAccount,
                bankAccountToken: session.bankAccountToken,
                status: session.status,
                statusDetails: session.statusDetails
            )
        } else {
            return session
        }
    }

    private func fetchAccounts(
        clientSecret: String,
        resultsSoFar: [StripeAPI.FinancialConnectionsAccount]
    ) async throws -> [StripeAPI.FinancialConnectionsAccount] {
        let maxAccountLimit = 100
        let lastId = resultsSoFar.last?.id

        let accounts: StripeAPI.FinancialConnectionsSession.AccountList = try await fetchFinancialConnectionsAccounts(
            clientSecret: clientSecret,
            startingAfterAccountId: lastId
        )

        let combinedAccounts = resultsSoFar + accounts.data
        guard accounts.hasMore, combinedAccounts.count < maxAccountLimit else {
            return combinedAccounts
        }

        // Recursive call
        return try await fetchAccounts(
            clientSecret: clientSecret,
            resultsSoFar: combinedAccounts
        )
    }

    func attachBankAccountToLinkAccountSession(
        clientSecret: String,
        accountNumber: String,
        routingNumber: String,
        consumerSessionClientSecret: String?
    ) async throws -> FinancialConnectionsPaymentAccountResource {
        try await attachPaymentAccountToLinkAccountSession(
            clientSecret: clientSecret,
            accountNumber: accountNumber,
            routingNumber: routingNumber,
            consumerSessionClientSecret: consumerSessionClientSecret
        )
    }

    func attachLinkedAccountIdToLinkAccountSession(
        clientSecret: String,
        linkedAccountId: String,
        consumerSessionClientSecret: String?
    ) async throws -> FinancialConnectionsPaymentAccountResource {
        try await attachPaymentAccountToLinkAccountSession(
            clientSecret: clientSecret,
            linkedAccountId: linkedAccountId,
            consumerSessionClientSecret: consumerSessionClientSecret
        )
    }

    private func attachPaymentAccountToLinkAccountSession(
        clientSecret: String,
        accountNumber: String? = nil,
        routingNumber: String? = nil,
        linkedAccountId: String? = nil,
        consumerSessionClientSecret: String? = nil
    ) async throws -> FinancialConnectionsPaymentAccountResource {
        var parameters: [String: Any] = [
            "client_secret": clientSecret,
        ]
        parameters["consumer_session_client_secret"] = consumerSessionClientSecret  // optional for Link
        if let accountNumber = accountNumber, let routingNumber = routingNumber {
            parameters["type"] = "bank_account"
            parameters["bank_account"] = [
                "routing_number": routingNumber,
                "account_number": accountNumber,
            ]
        } else if let linkedAccountId = linkedAccountId {
            parameters["type"] = "linked_account"
            parameters["linked_account"] = [
                "id": linkedAccountId,
            ]
        } else {
            assertionFailure()
            throw FinancialConnectionsSheetError
                .unknown(debugDescription: "Invalid usage of \(#function).")
        }

        return try await poll(
            initialPollDelay: 1.0
        ) { [weak self] in
            guard let self else {
                throw FinancialConnectionsSheetError.unknown(debugDescription: "FinancialConnectionsAsyncAPIClient deallocated.")
            }
            return try await self.post(endpoint: .attachPaymentAccount, parameters: parameters)
        }
    }

    func recordAuthSessionEvent(
        clientSecret: String,
        authSessionId: String,
        eventNamespace: String,
        eventName: String
    ) async throws -> EmptyResponse {
        let clientTimestamp = Date().timeIntervalSince1970.milliseconds
        var parameters: [String: Any] = [
            "id": authSessionId,
            "client_secret": clientSecret,
            "client_timestamp": clientTimestamp,
            "frontend_events": [
                [
                    "event_namespace": eventNamespace,
                    "event_name": eventName,
                    "client_timestamp": clientTimestamp,
                    "raw_event_details": "{}",
                ] as [String: Any],
            ],
        ]
        parameters["key"] = backingAPIClient.publishableKey
        return try await post(endpoint: .authSessionsEvents, parameters: parameters)
    }

    // MARK: - Networking

    func saveAccountsToNetworkAndLink(
        shouldPollAccounts: Bool,
        selectedAccounts: [FinancialConnectionsPartnerAccount]?,
        emailAddress: String?,
        phoneNumber: String?,
        country: String?,
        consumerSessionClientSecret: String?,
        clientSecret: String,
        isRelink: Bool
    ) async throws -> (
        manifest: FinancialConnectionsSessionManifest,
        customSuccessPaneMessage: String?
    ) {
        let saveAccountsToLinkHandler: () async throws -> (
            manifest: FinancialConnectionsSessionManifest,
            customSuccessPaneMessage: String?
        ) = {
            let manifest = try await self.saveAccountsToLink(
                emailAddress: emailAddress,
                phoneNumber: phoneNumber,
                country: country,
                selectedAccountIds: selectedAccounts?.map({ $0.id }),
                consumerSessionClientSecret: consumerSessionClientSecret,
                clientSecret: clientSecret
            )

            let customSuccessPaneMessage = isRelink ? nil : manifest.displayText?.successPane?.subCaption

            return (
                manifest: manifest,
                customSuccessPaneMessage: customSuccessPaneMessage
            )
        }
        if
            let linkedAccountIds = selectedAccounts?.compactMap({ $0.linkedAccountId }),
            shouldPollAccounts,
            !linkedAccountIds.isEmpty
        {
            do {
                _ = try await pollAccountNumbersForSelectedAccounts(linkedAccountIds: linkedAccountIds)
                let saveAccountsToLinkResult = try await saveAccountsToLinkHandler()
                return saveAccountsToLinkResult
            } catch {
                // ignoring return is intentional
                _ = try await disableNetworking(
                    disabledReason: "account_numbers_not_available",
                    clientSuggestedNextPaneOnDisableNetworking: nil,
                    clientSecret: clientSecret
                )
                throw error
            }
        } else {
            return try await saveAccountsToLinkHandler()
        }
    }

    private func pollAccountNumbersForSelectedAccounts(
        linkedAccountIds: [String]
    ) async throws -> EmptyResponse {
        let parameters: [String: Any] = [
            "linked_accounts": linkedAccountIds,
        ]
        return try await poll(
            initialPollDelay: 1.0,
            maxNumberOfRetries: 20
        ) { [weak self] in
            guard let self else {
                throw FinancialConnectionsSheetError.unknown(debugDescription: "FinancialConnectionsAsyncAPIClient deallocated.")
            }
            return try await self.get(endpoint: .pollAccountNumbers, parameters: parameters)
        }
    }

    private func saveAccountsToLink(
        emailAddress: String?,
        phoneNumber: String?,
        country: String?,
        selectedAccountIds: [String]?,
        consumerSessionClientSecret: String?,
        clientSecret: String
    ) async throws -> FinancialConnectionsSessionManifest {
        var parameters: [String: Any] = [
            "client_secret": clientSecret,
            "expand": ["active_auth_session"],
        ]
        parameters["selected_accounts"] = selectedAccountIds // null for manual entry
        parameters["email_address"] = emailAddress?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        parameters["phone_number"] = phoneNumber
        parameters["country"] = country
        parameters["locale"] = (phoneNumber != nil) ? Locale.current.toLanguageTag() : nil
        parameters["consumer_session_client_secret"] = consumerSessionClientSecret
        return try await post(endpoint: .saveAccountsToLink, parameters: parameters)
    }

    func disableNetworking(
        disabledReason: String?,
        clientSuggestedNextPaneOnDisableNetworking: String?,
        clientSecret: String
    ) async throws -> FinancialConnectionsSessionManifest {
        var parameters: [String: Any] = [
            "client_secret": clientSecret,
            "expand": ["active_auth_session"],
        ]
        parameters["disabled_reason"] = disabledReason
        parameters["client_requested_next_pane_on_disable_networking"] = clientSuggestedNextPaneOnDisableNetworking
        return try await post(endpoint: .disableNetworking, parameters: parameters)
    }

    func fetchNetworkedAccounts(
        clientSecret: String,
        consumerSessionClientSecret: String
    ) async throws -> FinancialConnectionsNetworkedAccountsResponse {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "consumer_session_client_secret": consumerSessionClientSecret,
            "expand": ["data.institution"],
        ]
        return try await get(endpoint: .networkedAccounts, parameters: parameters)
    }

    func selectNetworkedAccounts(
        selectedAccountIds: [String],
        clientSecret: String,
        consumerSessionClientSecret: String,
        consentAcquired: Bool?
    ) async throws -> ShareNetworkedAccountsResponse {
        var parameters: [String: Any] = [
            "selected_accounts": selectedAccountIds,
            "client_secret": clientSecret,
            "consumer_session_client_secret": consumerSessionClientSecret,
        ]
        parameters["consent_acquired"] = consentAcquired
        return try await post(endpoint: .shareNetworkedAccount, parameters: parameters)
    }

    func markLinkStepUpAuthenticationVerified(
        clientSecret: String
    ) async throws -> FinancialConnectionsSessionManifest {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "expand": ["active_auth_session"],
        ]
        return try await post(endpoint: .linkStepUpAuthenticationVerified, parameters: parameters)
    }

    func consumerSessionLookup(
        emailAddress: String,
        clientSecret: String,
        sessionId: String,
        emailSource: FinancialConnectionsAsyncAPIClient.EmailSource,
        useMobileEndpoints: Bool,
        pane: FinancialConnectionsSessionManifest.NextPane
    ) async throws -> LookupConsumerSessionResponse {
        var parameters: [String: Any] = [
            "email_address":
                emailAddress
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
        ]
        if useMobileEndpoints {
            parameters["request_surface"] = requestSurface
            parameters["session_id"] = sessionId
            parameters["email_source"] = emailSource.rawValue
            let updatedParameters = await assertAndApplyAttestationParameters(
                to: parameters,
                api: .consumerSessionLookup,
                pane: pane
            )
            return try await post(endpoint: .mobileConsumerSessionLookup, parameters: updatedParameters)
        } else {
            parameters["client_secret"] = clientSecret
            return try await post(endpoint: .consumerSessions, parameters: parameters)
        }
    }

    // MARK: - Link API's

    func consumerSessionStartVerification(
        otpType: String,
        customEmailType: String?,
        connectionsMerchantName: String?,
        consumerSessionClientSecret: String
    ) async throws -> ConsumerSessionResponse {
        var parameters: [String: Any] = [
            "request_surface": requestSurface,
            "type": otpType,
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret,
            ],
            "locale": Locale.current.toLanguageTag(),
        ]
        parameters["custom_email_type"] = customEmailType
        parameters["connections_merchant_name"] = connectionsMerchantName
        return try await post(endpoint: .startVerification, parameters: parameters)
    }

    func consumerSessionConfirmVerification(
        otpCode: String,
        otpType: String,
        consumerSessionClientSecret: String
    ) async throws -> ConsumerSessionResponse {
        let parameters: [String: Any] = [
            "type": otpType,
            "code": otpCode,
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret,
            ],
            "request_surface": requestSurface,
        ]
        return try await post(endpoint: .confirmVerification, parameters: parameters)
    }

    func markLinkVerified(
        clientSecret: String
    ) async throws -> FinancialConnectionsSessionManifest {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "expand": ["active_auth_session"],
        ]
        return try await post(endpoint: .linkVerified, parameters: parameters)
    }

    func linkAccountSignUp(
        emailAddress: String,
        phoneNumber: String,
        country: String,
        amount: Int?,
        currency: String?,
        incentiveEligibilitySession: ElementsSessionContext.IntentID?,
        useMobileEndpoints: Bool,
        pane: FinancialConnectionsSessionManifest.NextPane
    ) async throws -> LinkSignUpResponse {
        var parameters: [String: Any] = [
            "request_surface": requestSurface,
            "email_address": emailAddress
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
            "phone_number": phoneNumber,
            "country": country,
            "country_inferring_method": "PHONE_NUMBER",
            "locale": Locale.current.toLanguageTag(),
            "consent_action": "entered_phone_number_clicked_save_to_link",
        ]

        if let amount, let currency {
            parameters["amount"] = amount
            parameters["currency"] = currency
        }

        if let incentiveEligibilitySession {
            switch incentiveEligibilitySession {
            case .payment(let paymentIntentId):
                parameters["financial_incentive"] = [
                    "payment_intent": paymentIntentId,
                ]
            case .setup(let setupIntentId):
                parameters["financial_incentive"] = [
                    "setup_intent": setupIntentId,
                ]
            case .deferred(let elementsSessionId):
                parameters["financial_incentive"] = [
                    "elements_session_id": elementsSessionId,
                ]
            }
        }
        if useMobileEndpoints {
            let updatedParameters = await assertAndApplyAttestationParameters(
                to: parameters,
                api: .linkSignUp,
                pane: pane
            )
            return try await post(endpoint: .mobileLinkAccountSignup, parameters: updatedParameters)
        } else {
            return try await post(endpoint: .linkAccountsSignUp, parameters: parameters)
        }
    }

    func attachLinkConsumerToLinkAccountSession(
        linkAccountSession: String,
        consumerSessionClientSecret: String
    ) async throws -> AttachLinkConsumerToLinkAccountSessionResponse {
        let parameters: [String: Any] = [
            "request_surface": requestSurface,
            "link_account_session": linkAccountSession,
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret
            ],
        ]
        return try await post(endpoint: .attachLinkConsumerToLinkAccountSession, parameters: parameters)
    }

    func paymentDetails(
        consumerSessionClientSecret: String,
        bankAccountId: String,
        billingAddress: BillingAddress?,
        billingEmail: String?
    ) async throws -> FinancialConnectionsPaymentDetails {
        var parameters: [String: Any] = [
            "request_surface": requestSurface,
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret
            ],
            "bank_account": [
                "account": bankAccountId
            ],
            "type": "bank_account",
        ]

        if let billingAddress {
            let encodedBillingAddress = try Self.encodeAsParameters(billingAddress)
            parameters["billing_address"] = encodedBillingAddress
        }

        if let billingEmail, !billingEmail.isEmpty {
            parameters["billing_email_address"] = billingEmail.lowercased()
        }

        return try await post(endpoint: .paymentDetails, parameters: parameters)
    }

    func sharePaymentDetails(
        consumerSessionClientSecret: String,
        paymentDetailsId: String,
        expectedPaymentMethodType: String,
        billingEmail: String?,
        billingPhone: String?
    ) async throws -> FinancialConnectionsSharePaymentDetails {
        var parameters: [String: Any] = [
            "request_surface": requestSurface,
            "id": paymentDetailsId,
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret
            ],
            "expected_payment_method_type": expectedPaymentMethodType,
            "expand": ["payment_method"],
        ]

        if let billingEmail {
            parameters["billing_email"] = billingEmail
        }

        if let billingPhone {
            parameters["billing_phone"] = billingPhone
        }

        let parametersWithFraudDetection = await updateAndApplyFraudDetection(to: parameters)
        return try await post(endpoint: .sharePaymentDetails, parameters: parametersWithFraudDetection)
    }

    func paymentMethods(
        consumerSessionClientSecret: String,
        paymentDetailsId: String,
        billingDetails: ElementsSessionContext.BillingDetails?
    ) async throws -> LinkBankPaymentMethod {
        var parameters: [String: Any] = [
            "link": [
                "credentials": [
                    "consumer_session_client_secret": consumerSessionClientSecret
                ],
                "payment_details_id": paymentDetailsId,
            ],
            "type": "link",
        ]

        if let billingDetails {
            let encodedBillingAddress = try Self.encodeAsParameters(billingDetails)
            parameters["billing_details"] = encodedBillingAddress
        }

        let parametersWithFraudDetection = await updateAndApplyFraudDetection(to: parameters)
        return try await post(endpoint: .paymentMethods, parameters: parametersWithFraudDetection)
    }

    func updateAvailableIncentives(
        consumerSessionClientSecret: String,
        sessionID: String,
        paymentDetailsID: String
    ) async throws -> AvailableIncentives {
        let parameters: [String: Any] = [
            "request_surface": requestSurface,
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret
            ],
            "session_id": sessionID,
            "payment_details_id": paymentDetailsID,
        ]
        return try await post(endpoint: .availableIncentives, parameters: parameters)
    }
}
