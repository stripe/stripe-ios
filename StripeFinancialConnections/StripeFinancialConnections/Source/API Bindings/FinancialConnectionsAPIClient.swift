//
//  FinancialConnectionsAPIClient.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/1/21.
//

import Foundation
@_spi(STP) import StripeCore

protocol FinancialConnectionsAPIClient {

    func synchronize(
        clientSecret: String,
        returnURL: String?
    ) -> Future<FinancialConnectionsSynchronize>

    func fetchFinancialConnectionsAccounts(
        clientSecret: String,
        startingAfterAccountId: String?
    ) -> Promise<StripeAPI.FinancialConnectionsSession.AccountList>

    func fetchFinancialConnectionsSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession>

    func markConsentAcquired(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest>

    func fetchFeaturedInstitutions(clientSecret: String) -> Promise<FinancialConnectionsInstitutionList>

    func fetchInstitutions(clientSecret: String, query: String) -> Future<FinancialConnectionsInstitutionSearchResultResource>

    func createAuthSession(clientSecret: String, institutionId: String) -> Promise<FinancialConnectionsAuthSession>

    func cancelAuthSession(clientSecret: String, authSessionId: String) -> Promise<FinancialConnectionsAuthSession>

    func retrieveAuthSession(
        clientSecret: String,
        authSessionId: String
    ) -> Future<FinancialConnectionsAuthSession>

    func fetchAuthSessionOAuthResults(clientSecret: String, authSessionId: String) -> Future<
        FinancialConnectionsMixedOAuthParams
    >

    func authorizeAuthSession(
        clientSecret: String,
        authSessionId: String,
        publicToken: String?
    ) -> Promise<FinancialConnectionsAuthSession>

    func fetchAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        initialPollDelay: TimeInterval
    ) -> Future<FinancialConnectionsAuthSessionAccounts>

    func selectAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        selectedAccountIds: [String]
    ) -> Promise<FinancialConnectionsAuthSessionAccounts>

    func markLinkingMoreAccounts(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest>

    func completeFinancialConnectionsSession(
        clientSecret: String,
        terminalError: String?
    ) -> Future<StripeAPI.FinancialConnectionsSession>

    func attachBankAccountToLinkAccountSession(
        clientSecret: String,
        accountNumber: String,
        routingNumber: String
    ) -> Future<FinancialConnectionsPaymentAccountResource>

    func attachLinkedAccountIdToLinkAccountSession(
        clientSecret: String,
        linkedAccountId: String,
        consumerSessionClientSecret: String?
    ) -> Future<FinancialConnectionsPaymentAccountResource>

    func recordAuthSessionEvent(
        clientSecret: String,
        authSessionId: String,
        eventNamespace: String,
        eventName: String
    ) -> Future<EmptyResponse>

    // MARK: - Networking

    func saveAccountsToNetworkAndLink(
        shouldPollAccounts: Bool,
        selectedAccounts: [FinancialConnectionsPartnerAccount],
        emailAddress: String?,
        phoneNumber: String?,
        country: String?,
        consumerSessionClientSecret: String?,
        clientSecret: String
    ) -> Future<(
        manifest: FinancialConnectionsSessionManifest,
        customSuccessPaneMessage: String?
    )>

    func disableNetworking(
        disabledReason: String?,
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest>

    func fetchNetworkedAccounts(
        clientSecret: String,
        consumerSessionClientSecret: String
    ) -> Future<FinancialConnectionsNetworkedAccountsResponse>

    func selectNetworkedAccounts(
        selectedAccountIds: [String],
        clientSecret: String,
        consumerSessionClientSecret: String
    ) -> Future<FinancialConnectionsInstitutionList>

    func markLinkStepUpAuthenticationVerified(
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest>

    func consumerSessionLookup(
        emailAddress: String,
        clientSecret: String
    ) -> Future<LookupConsumerSessionResponse>

    // MARK: - Link API's

    func consumerSessionStartVerification(
        otpType: String,
        customEmailType: String?,
        connectionsMerchantName: String?,
        consumerSessionClientSecret: String
    ) -> Future<ConsumerSessionResponse>

    func consumerSessionConfirmVerification(
        otpCode: String,
        otpType: String,
        consumerSessionClientSecret: String
    ) -> Future<ConsumerSessionResponse>

    func markLinkVerified(
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest>
}

extension STPAPIClient: FinancialConnectionsAPIClient {

    func fetchFinancialConnectionsAccounts(
        clientSecret: String,
        startingAfterAccountId: String?
    ) -> Promise<StripeAPI.FinancialConnectionsSession.AccountList> {
        var parameters = ["client_secret": clientSecret]
        if let startingAfterAccountId = startingAfterAccountId {
            parameters["starting_after"] = startingAfterAccountId
        }
        return self.get(
            resource: APIEndpointListAccounts,
            parameters: parameters
        )
    }

    func fetchFinancialConnectionsSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession> {
        return self.get(
            resource: APIEndpointSessionReceipt,
            parameters: ["client_secret": clientSecret]
        )
    }

    func synchronize(
        clientSecret: String,
        returnURL: String?
    ) -> Future<FinancialConnectionsSynchronize> {
        let parameters: [String: Any] = [
            "expand": ["manifest.active_auth_session"],
            "client_secret": clientSecret,
            "mobile": {
                var mobileParameters: [String: Any] = [
                    "fullscreen": true,
                    "hide_close_button": true,
                    "forced_authflow_version": "v3",
                ]
                mobileParameters["app_return_url"] = returnURL
                return mobileParameters
            }(),
            "locale": Locale.current.toLanguageTag(),
        ]
        return self.post(
            resource: "financial_connections/sessions/synchronize",
            parameters: parameters
        )
    }

    func markConsentAcquired(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        let parameters = [
            "client_secret": clientSecret,
        ]
        return self.post(
            resource: APIEndpointConsentAcquired,
            parameters: parameters
        )
    }

    func fetchFeaturedInstitutions(clientSecret: String) -> Promise<FinancialConnectionsInstitutionList> {
        let parameters = [
            "client_secret": clientSecret,
        ]
        return self.get(
            resource: APIEndpointFeaturedInstitutions,
            parameters: parameters
        )
    }

    func fetchInstitutions(clientSecret: String, query: String) -> Future<FinancialConnectionsInstitutionSearchResultResource> {
        let parameters = [
            "client_secret": clientSecret,
            "query": query,
            "limit": "20",
        ]
        return self.get(
            resource: APIEndpointSearchInstitutions,
            parameters: parameters
        )
    }

    func createAuthSession(clientSecret: String, institutionId: String) -> Promise<FinancialConnectionsAuthSession> {
        let body: [String: Any] = [
            "client_secret": clientSecret,
            "institution": institutionId,
            "use_mobile_handoff": "false",
            "use_abstract_flow": true,
            "return_url": "ios",
        ]
        return self.post(resource: APIEndpointAuthSessions, parameters: body)
    }

    func cancelAuthSession(clientSecret: String, authSessionId: String) -> Promise<FinancialConnectionsAuthSession> {
        let body = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]
        return self.post(resource: APIEndpointAuthSessionsCancel, object: body)
    }

    func retrieveAuthSession(
        clientSecret: String,
        authSessionId: String
    ) -> Future<FinancialConnectionsAuthSession> {
        let body: [String: Any] = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]
        return self.post(resource: APIEndpointAuthSessionsRetrieve, parameters: body)
    }

    func fetchAuthSessionOAuthResults(clientSecret: String, authSessionId: String) -> Future<
        FinancialConnectionsMixedOAuthParams
    > {
        let body = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]
        let pollingHelper = APIPollingHelper(
            apiCall: { [weak self] in
                guard let self = self else {
                    return Promise(
                        error: FinancialConnectionsSheetError.unknown(debugDescription: "STPAPIClient deallocated.")
                    )
                }
                return self.post(resource: APIEndpointAuthSessionsOAuthResults, object: body)
            },
            pollTimingOptions: APIPollingHelper<FinancialConnectionsMixedOAuthParams>.PollTimingOptions(
                initialPollDelay: 0,
                maxNumberOfRetries: 300,  // Stripe.js has 600 second timeout, 600 / 2 = 300 retries
                retryInterval: 2.0
            )
        )
        return pollingHelper.startPollingApiCall()
    }

    func authorizeAuthSession(
        clientSecret: String,
        authSessionId: String,
        publicToken: String? = nil
    ) -> Promise<FinancialConnectionsAuthSession> {
        var body = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]
        body["public_token"] = publicToken  // not all integrations require public_token
        return self.post(resource: APIEndpointAuthSessionsAuthorized, object: body)
    }

    func fetchAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        initialPollDelay: TimeInterval
    ) -> Future<FinancialConnectionsAuthSessionAccounts> {
        let body: [String: Any] = [
            "client_secret": clientSecret,
            "id": authSessionId,
            "expand": ["data.institution"],
        ]
        let pollingHelper = APIPollingHelper(
            apiCall: { [weak self] in
                guard let self = self else {
                    return Promise(
                        error: FinancialConnectionsSheetError.unknown(debugDescription: "STPAPIClient deallocated.")
                    )
                }
                return self.post(resource: APIEndpointAuthSessionsAccounts, parameters: body)
            },
            pollTimingOptions: APIPollingHelper<FinancialConnectionsAuthSessionAccounts>.PollTimingOptions(
                initialPollDelay: initialPollDelay
            )
        )
        return pollingHelper.startPollingApiCall()
    }

    func selectAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        selectedAccountIds: [String]
    ) -> Promise<FinancialConnectionsAuthSessionAccounts> {
        let body: [String: Any] = [
            "client_secret": clientSecret,
            "id": authSessionId,
            "selected_accounts": selectedAccountIds,
            "expand": ["data.institution"],
        ]
        return self.post(resource: APIEndpointAuthSessionsSelectedAccounts, parameters: body)
    }

    func markLinkingMoreAccounts(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        let body = [
            "client_secret": clientSecret,
        ]
        return self.post(resource: APIEndpointLinkMoreAccounts, object: body)
    }

    func completeFinancialConnectionsSession(
        clientSecret: String,
        terminalError: String?
    ) -> Future<StripeAPI.FinancialConnectionsSession> {
        var body: [String: Any] = [
            "client_secret": clientSecret,
        ]
        body["terminal_error"] = terminalError
        return self.post(resource: APIEndpointComplete, parameters: body)
            .chained { (session: StripeAPI.FinancialConnectionsSession) in
                if session.accounts.hasMore {
                    // de-paginate the accounts we get from the session because
                    // we want to give the clients a full picture of the number
                    // of accounts that were linked
                    let accountAPIFetcher = FinancialConnectionsAccountAPIFetcher(
                        api: self,
                        clientSecret: clientSecret
                    )
                    return
                        accountAPIFetcher
                        .fetchAccounts(initial: session.accounts.data)
                        .chained { [accountAPIFetcher] accounts in
                            _ = accountAPIFetcher  // retain `accountAPIFetcher` for the duration of the network call
                            return Promise(
                                value: StripeAPI.FinancialConnectionsSession(
                                    clientSecret: session.clientSecret,
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
                            )
                        }
                } else {
                    return Promise(value: session)
                }
            }
    }

    func attachBankAccountToLinkAccountSession(
        clientSecret: String,
        accountNumber: String,
        routingNumber: String
    ) -> Future<FinancialConnectionsPaymentAccountResource> {
        return attachPaymentAccountToLinkAccountSession(
            clientSecret: clientSecret,
            accountNumber: accountNumber,
            routingNumber: routingNumber
        )
    }

    func attachLinkedAccountIdToLinkAccountSession(
        clientSecret: String,
        linkedAccountId: String,
        consumerSessionClientSecret: String?
    ) -> Future<FinancialConnectionsPaymentAccountResource> {
        return attachPaymentAccountToLinkAccountSession(
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
    ) -> Future<FinancialConnectionsPaymentAccountResource> {
        var body: [String: Any] = [
            "client_secret": clientSecret,
        ]
        if let accountNumber = accountNumber, let routingNumber = routingNumber {
            body["type"] = "bank_account"
            body["bank_account"] = [
                "routing_number": routingNumber,
                "account_number": accountNumber,
            ]
        } else if let linkedAccountId = linkedAccountId {
            body["type"] = "linked_account"
            body["linked_account"] = [
                "id": linkedAccountId,
            ]
            body["consumer_session_client_secret"] = consumerSessionClientSecret  // optional for Link
        } else {
            assertionFailure()
            return Promise(
                error:
                    FinancialConnectionsSheetError
                    .unknown(debugDescription: "Invalid usage of \(#function).")
            )
        }

        let pollingHelper = APIPollingHelper(
            apiCall: { [weak self] in
                guard let self = self else {
                    return Promise(
                        error: FinancialConnectionsSheetError.unknown(debugDescription: "STPAPIClient deallocated.")
                    )
                }
                return self.post(resource: APIEndpointAttachPaymentAccount, parameters: body)
            },
            pollTimingOptions: APIPollingHelper<FinancialConnectionsPaymentAccountResource>.PollTimingOptions(
                initialPollDelay: 1.0
            )
        )
        return pollingHelper.startPollingApiCall()
    }

    func recordAuthSessionEvent(
        clientSecret: String,
        authSessionId: String,
        eventNamespace: String,
        eventName: String
    ) -> Future<EmptyResponse> {
        let clientTimestamp = Date().timeIntervalSince1970.milliseconds
        var body: [String: Any] = [
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
        body["key"] = publishableKey
        return self.post(
            resource: APIEndpointAuthSessionsEvents,
            parameters: body
        )
    }

    // MARK: - Networking

    func saveAccountsToNetworkAndLink(
        shouldPollAccounts: Bool,
        selectedAccounts: [FinancialConnectionsPartnerAccount],
        emailAddress: String?,
        phoneNumber: String?,
        country: String?,
        consumerSessionClientSecret: String?,
        clientSecret: String
    ) -> Future<(
        manifest: FinancialConnectionsSessionManifest,
        customSuccessPaneMessage: String?
    )> {
        let saveAccountsToLinkHandler: () -> Future<(
            manifest: FinancialConnectionsSessionManifest,
            customSuccessPaneMessage: String?
        )> = {
            return self.saveAccountsToLink(
                emailAddress: emailAddress,
                phoneNumber: phoneNumber,
                country: country,
                selectedAccountIds: selectedAccounts.map({ $0.id }),
                consumerSessionClientSecret: consumerSessionClientSecret,
                clientSecret: clientSecret
            )
            .chained { manifest in
                return Promise(
                    value: (
                        manifest: manifest,
                        customSuccessPaneMessage: manifest.displayText?.successPane?.subCaption
                    )
                )
            }
        }
        let linkedAccountIds = selectedAccounts.compactMap({ $0.linkedAccountId })
        if
            shouldPollAccounts,
            !linkedAccountIds.isEmpty
        {
            let promise = Promise<(
                manifest: FinancialConnectionsSessionManifest,
                customSuccessPaneMessage: String?
            )>()
            pollAccountNumbersForSelectedAccounts(
                linkedAccountIds: linkedAccountIds
            )
            .observe { result in
                switch result {
                case .success:
                    saveAccountsToLinkHandler()
                        .observe { result in
                            promise.fullfill(with: result)
                        }
                case .failure(let error):
                    self.disableNetworking(
                        disabledReason: "account_numbers_not_available",
                        clientSecret: clientSecret
                    ).observe { _ in } // ignoring return is intentional

                    promise.reject(with: error)
                }
            }
            return promise
        } else {
            return saveAccountsToLinkHandler()
        }
    }

    private func pollAccountNumbersForSelectedAccounts(
        linkedAccountIds: [String]
    ) -> Future<EmptyResponse> {
        let body: [String: Any] = [
            "linked_accounts": linkedAccountIds,
        ]
        let pollingHelper = APIPollingHelper(
            apiCall: { [weak self] in
                guard let self = self else {
                    return Promise(
                        error: FinancialConnectionsSheetError.unknown(
                            debugDescription: "STPAPIClient deallocated."
                        )
                    )
                }
                return self.get(
                    resource: APIEndpointPollAccountNumbers,
                    parameters: body
                )
            },
            pollTimingOptions: APIPollingHelper<EmptyResponse>.PollTimingOptions(
                initialPollDelay: 1.0,
                maxNumberOfRetries: 20
            )
        )
        return pollingHelper.startPollingApiCall()
    }

    private func saveAccountsToLink(
        emailAddress: String?,
        phoneNumber: String?,
        country: String?,
        selectedAccountIds: [String],
        consumerSessionClientSecret: String?,
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest> {
        var body: [String: Any] = [
            "client_secret": clientSecret,
            "selected_accounts": selectedAccountIds,
            "expand": ["active_auth_session"],
        ]
        body["email_address"] = emailAddress?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        body["phone_number"] = phoneNumber
        body["country"] = country
        body["locale"] = (phoneNumber != nil) ? Locale.current.toLanguageTag() : nil
        body["consumer_session_client_secret"] = consumerSessionClientSecret
        return post(resource: APIEndpointSaveAccountsToLink, parameters: body)
    }

    func disableNetworking(
        disabledReason: String?,
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest> {
        var body: [String: Any] = [
            "client_secret": clientSecret,
            "expand": ["active_auth_session"],
        ]
        body["disabled_reason"] = disabledReason
        return post(resource: APIEndpointDisableNetworking, parameters: body)
    }

    func markLinkVerified(
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest> {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "expand": ["active_auth_session"],
        ]
        return post(resource: APIEndpointLinkVerified, parameters: parameters)
    }

    func fetchNetworkedAccounts(
        clientSecret: String,
        consumerSessionClientSecret: String
    ) -> Future<FinancialConnectionsNetworkedAccountsResponse> {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "consumer_session_client_secret": consumerSessionClientSecret,
            "expand": ["data.institution"],
        ]
        return get(resource: APIEndpointNetworkedAccounts, parameters: parameters)
    }

    func selectNetworkedAccounts(
        selectedAccountIds: [String],
        clientSecret: String,
        consumerSessionClientSecret: String
    ) -> Future<FinancialConnectionsInstitutionList> {
        let parameters: [String: Any] = [
            "selected_accounts": selectedAccountIds,
            "client_secret": clientSecret,
            "consumer_session_client_secret": consumerSessionClientSecret,
        ]
        return post(resource: APIEndpointShareNetworkedAccount, parameters: parameters)
    }

    func markLinkStepUpAuthenticationVerified(
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest> {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "expand": ["active_auth_session"],
        ]
        return post(resource: APIEndpointLinkStepUpAuthenticationVerified, parameters: parameters)
    }

    func consumerSessionLookup(
        emailAddress: String,
        clientSecret: String
    ) -> Future<LookupConsumerSessionResponse> {
        let parameters: [String: Any] = [
            "email_address":
                emailAddress
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
            "client_secret": clientSecret,
        ]
        return post(resource: APIEndpointConsumerSessions, parameters: parameters)
    }

    // MARK: - Link API's

    func consumerSessionStartVerification(
        otpType: String,
        customEmailType: String?,
        connectionsMerchantName: String?,
        consumerSessionClientSecret: String
    ) -> Future<ConsumerSessionResponse> {
        var parameters: [String: Any] = [
            "request_surface": "ios_connections",
            "type": otpType,
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret,
            ],
            "locale": Locale.current.toLanguageTag(),
        ]
        parameters["custom_email_type"] = customEmailType
        parameters["connections_merchant_name"] = connectionsMerchantName
        return post(resource: "consumers/sessions/start_verification", parameters: parameters)
    }

    func consumerSessionConfirmVerification(
        otpCode: String,
        otpType: String,
        consumerSessionClientSecret: String
    ) -> Future<ConsumerSessionResponse> {
        let parameters: [String: Any] = [
            "type": otpType,
            "code": otpCode,
            "credentials": [
                "consumer_session_client_secret": consumerSessionClientSecret,
            ],
            "request_surface": "ios_connections",
        ]
        return post(resource: "consumers/sessions/confirm_verification", parameters: parameters)
    }
}

private let APIEndpointListAccounts = "link_account_sessions/list_accounts"
private let APIEndpointAttachPaymentAccount = "link_account_sessions/attach_payment_account"
private let APIEndpointSessionReceipt = "link_account_sessions/session_receipt"
private let APIEndpointGenerateHostedURL = "link_account_sessions/generate_hosted_url"
private let APIEndpointConsentAcquired = "link_account_sessions/consent_acquired"
private let APIEndpointLinkMoreAccounts = "link_account_sessions/link_more_accounts"
private let APIEndpointComplete = "link_account_sessions/complete"
private let APIEndpointFeaturedInstitutions = "connections/featured_institutions"
private let APIEndpointSearchInstitutions = "connections/institutions"
private let APIEndpointAuthSessions = "connections/auth_sessions"
private let APIEndpointAuthSessionsCancel = "connections/auth_sessions/cancel"
private let APIEndpointAuthSessionsRetrieve = "connections/auth_sessions/retrieve"
private let APIEndpointAuthSessionsOAuthResults = "connections/auth_sessions/oauth_results"
private let APIEndpointAuthSessionsAuthorized = "connections/auth_sessions/authorized"
private let APIEndpointAuthSessionsAccounts = "connections/auth_sessions/accounts"
private let APIEndpointAuthSessionsSelectedAccounts = "connections/auth_sessions/selected_accounts"
private let APIEndpointAuthSessionsEvents = "connections/auth_sessions/events"
// Networking
private let APIEndpointDisableNetworking = "link_account_sessions/disable_networking"
private let APIEndpointLinkStepUpAuthenticationVerified = "link_account_sessions/link_step_up_authentication_verified"
private let APIEndpointLinkVerified = "link_account_sessions/link_verified"
private let APIEndpointNetworkedAccounts = "link_account_sessions/networked_accounts"
private let APIEndpointSaveAccountsToLink = "link_account_sessions/save_accounts_to_link"
private let APIEndpointShareNetworkedAccount = "link_account_sessions/share_networked_account"
private let APIEndpointConsumerSessions = "connections/link_account_sessions/consumer_sessions"
private let APIEndpointPollAccountNumbers = "link_account_sessions/poll_account_numbers"
