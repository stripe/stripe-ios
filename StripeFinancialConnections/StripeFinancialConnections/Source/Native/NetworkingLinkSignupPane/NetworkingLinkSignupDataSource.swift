//
//  NetworkingLinkSignupDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/17/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkingLinkSignupDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var elementsSessionContext: ElementsSessionContext? { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func synchronize() -> Future<FinancialConnectionsNetworkingLinkSignup>
    func lookup(emailAddress: String, manuallyEntered: Bool) -> Future<LookupConsumerSessionResponse>
    func saveToLink(
        emailAddress: String,
        phoneNumber: String,
        countryCode: String
    ) -> Future<String?>
    func completeAssertionIfNeeded(
        possibleError: Error?,
        api: FinancialConnectionsAPIClientLogger.API
    ) -> Error?
}

final class NetworkingLinkSignupDataSourceImplementation: NetworkingLinkSignupDataSource {

    let manifest: FinancialConnectionsSessionManifest
    let elementsSessionContext: ElementsSessionContext?
    private let selectedAccounts: [FinancialConnectionsPartnerAccount]?
    private let returnURL: String?
    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    init(
        manifest: FinancialConnectionsSessionManifest,
        selectedAccounts: [FinancialConnectionsPartnerAccount]?,
        returnURL: String?,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        elementsSessionContext: ElementsSessionContext?
    ) {
        self.manifest = manifest
        self.selectedAccounts = selectedAccounts
        self.returnURL = returnURL
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        self.elementsSessionContext = elementsSessionContext
    }

    func synchronize() -> Future<FinancialConnectionsNetworkingLinkSignup> {
        return apiClient.synchronize(
            clientSecret: clientSecret,
            returnURL: returnURL,
            initialSynchronize: false
        )
        .chained { synchronize in
            if let networkingLinkSignup = synchronize.text?.networkingLinkSignupPane {
                return Promise(value: networkingLinkSignup)
            } else {
                return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "no networkingLinkSignup data attached"))
            }
        }
    }

    func lookup(emailAddress: String, manuallyEntered: Bool) -> Future<LookupConsumerSessionResponse> {
        return apiClient.consumerSessionLookup(
            emailAddress: emailAddress,
            clientSecret: clientSecret,
            sessionId: manifest.id,
            emailSource: manuallyEntered ? .userAction : .customerObject,
            useMobileEndpoints: manifest.verified,
            pane: .networkingLinkSignupPane
        )
    }

    func saveToLink(
        emailAddress: String,
        phoneNumber: String,
        countryCode: String
    ) -> Future<String?> {
        if manifest.verified {
            // In the verified scenario, first call the `/mobile/sign_up` endpoint with attestation parameters,
            // then call `/save_accounts_to_link` and omit the email and phone parameters.
            return apiClient.linkAccountSignUp(
                emailAddress: emailAddress,
                phoneNumber: phoneNumber,
                country: countryCode,
                amount: nil,
                currency: nil,
                incentiveEligibilitySession: nil,
                useMobileEndpoints: manifest.verified,
                pane: .networkingLinkSignupPane
            ).chained { [weak self] response -> Future<FinancialConnectionsAPI.SaveAccountsToNetworkAndLinkResponse> in
                guard let self else {
                    return Promise(error: FinancialConnectionsSheetError.unknown(
                        debugDescription: "Networking Link Signup data source deallocated.")
                    )
                }
                // Intentionally omit email and phone in this subsequent call
                return apiClient.saveAccountsToNetworkAndLink(
                    shouldPollAccounts: !manifest.shouldAttachLinkedPaymentMethod,
                    selectedAccounts: selectedAccounts,
                    emailAddress: nil,
                    phoneNumber: nil,
                    country: nil,
                    consumerSessionClientSecret: response.consumerSession.clientSecret,
                    clientSecret: clientSecret,
                    isRelink: false
                )
            }
            .chained { (_, customSuccessPaneMessage) in
                return Promise(value: customSuccessPaneMessage)
            }
        } else {
            return apiClient.saveAccountsToNetworkAndLink(
                shouldPollAccounts: !manifest.shouldAttachLinkedPaymentMethod,
                selectedAccounts: selectedAccounts,
                emailAddress: emailAddress,
                phoneNumber: phoneNumber,
                country: countryCode, // ex. "US"
                consumerSessionClientSecret: nil,
                clientSecret: clientSecret,
                isRelink: false
            ).chained { (_, customSuccessPaneMessage) in
                return Promise(value: customSuccessPaneMessage)
            }
        }
    }

    // Marks the assertion as completed and logs possible errors during verified flows.
    func completeAssertionIfNeeded(
        possibleError: Error?,
        api: FinancialConnectionsAPIClientLogger.API
    ) -> Error? {
        guard manifest.verified else { return nil }
        return apiClient.completeAssertion(
            possibleError: possibleError,
            api: api,
            pane: .networkingLinkSignupPane
        )
    }
}
