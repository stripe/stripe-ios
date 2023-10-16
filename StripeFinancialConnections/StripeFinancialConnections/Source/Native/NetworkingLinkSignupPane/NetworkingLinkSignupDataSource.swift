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
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func synchronize() -> Future<FinancialConnectionsNetworkingLinkSignup>
    func lookup(emailAddress: String) -> Future<LookupConsumerSessionResponse>
    func saveToLink(emailAddress: String, phoneNumber: String, countryCode: String) -> Future<Void>
}

final class NetworkingLinkSignupDataSourceImplementation: NetworkingLinkSignupDataSource {

    let manifest: FinancialConnectionsSessionManifest
    private let selectedAccountIds: [String]
    private let returnURL: String?
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    init(
        manifest: FinancialConnectionsSessionManifest,
        selectedAccountIds: [String],
        returnURL: String?,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.selectedAccountIds = selectedAccountIds
        self.returnURL = returnURL
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
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

    func saveToLink(emailAddress: String, phoneNumber: String, countryCode: String) -> Future<Void> {
        return apiClient.saveAccountsToLink(
            emailAddress: emailAddress,
            phoneNumber: phoneNumber,
            country: countryCode, // ex. "US"
            selectedAccountIds: selectedAccountIds,
            consumerSessionClientSecret: nil,
            clientSecret: clientSecret
        )
        .chained { _ in
            return Promise(value: ())
        }
    }
}
