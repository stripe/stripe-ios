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
    func lookup(emailAddress: String) -> Future<LookupConsumerSessionResponse>
    func saveToLink(
        emailAddress: String,
        phoneNumber: String,
        countryCode: String
    ) -> Future<String?>
    func completeAssertion(possibleError: Error?)
}

final class NetworkingLinkSignupDataSourceImplementation: NetworkingLinkSignupDataSource {

    let manifest: FinancialConnectionsSessionManifest
    let elementsSessionContext: ElementsSessionContext?
    private let selectedAccounts: [FinancialConnectionsPartnerAccount]?
    private let returnURL: String?
    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    private var verified: Bool {
        manifest.appVerificationEnabled ?? false
    }

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
            returnURL: returnURL
        )
        .chained { synchronize in
            if let networkingLinkSignup = synchronize.text?.networkingLinkSignupPane {
                return Promise(value: networkingLinkSignup)
            } else {
                return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "no networkingLinkSignup data attached"))
            }
        }
    }

    func lookup(emailAddress: String) -> Future<LookupConsumerSessionResponse> {
        return apiClient.consumerSessionLookup(emailAddress: emailAddress, clientSecret: clientSecret)
    }

    func saveToLink(
        emailAddress: String,
        phoneNumber: String,
        countryCode: String
    ) -> Future<String?> {
        if verified {
            // In the verified scenario, first call the `/mobile/sign_up` endpoint with attestation parameters,
            // then call `/save_accounts_to_link` and omit the email and phone parameters.
            return apiClient.linkAccountSignUp(
                emailAddress: emailAddress,
                phoneNumber: phoneNumber,
                country: countryCode,
                amount: nil,
                currency: nil,
                incentiveEligibilitySession: nil,
                useMobileEndpoints: verified
            ).chained { [weak self] _ -> Future<FinancialConnectionsAPI.SaveAccountsToNetworkAndLinkResponse> in
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
                    country: countryCode,
                    consumerSessionClientSecret: nil,
                    clientSecret: clientSecret
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
                clientSecret: clientSecret
            ).chained { (_, customSuccessPaneMessage) in
                return Promise(value: customSuccessPaneMessage)
            }
        }
    }

    func completeAssertion(possibleError: Error?) {
        guard verified else { return }
        apiClient.completeAssertion(possibleError: possibleError)
    }
}
