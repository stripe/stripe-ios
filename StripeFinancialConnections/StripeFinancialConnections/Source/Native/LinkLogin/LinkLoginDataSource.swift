//
//  LinkLoginDataSource.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-07-25.
//

import Foundation
@_spi(STP) import StripeCore

protocol LinkLoginDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func synchronize() -> Future<FinancialConnectionsLinkLoginPane>
    func lookup(emailAddress: String) -> Future<LookupConsumerSessionResponse>
    func signUp(
        emailAddress: String,
        phoneNumber: String,
        country: String
    ) -> Future<LinkSignUpResponse>
    func attachToAccountAndSynchronize(
        with linkSignUpResponse: LinkSignUpResponse
    ) -> Future<FinancialConnectionsSynchronize>
}

final class LinkLoginDataSourceImplementation: LinkLoginDataSource {
    private static let deallocatedError = FinancialConnectionsSheetError.unknown(debugDescription: "data source deallocated")

    let manifest: FinancialConnectionsSessionManifest
    let analyticsClient: FinancialConnectionsAnalyticsClient

    private let clientSecret: String
    private let returnURL: String?
    private let apiClient: FinancialConnectionsAPIClient

    init(
        manifest: FinancialConnectionsSessionManifest,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        clientSecret: String,
        returnURL: String?,
        apiClient: FinancialConnectionsAPIClient
    ) {
        self.manifest = manifest
        self.analyticsClient = analyticsClient
        self.clientSecret = clientSecret
        self.returnURL = returnURL
        self.apiClient = apiClient
    }

    func synchronize() -> Future<FinancialConnectionsLinkLoginPane> {
        apiClient.synchronize(
            clientSecret: clientSecret,
            returnURL: returnURL
        )
        .chained { synchronize in
            if let linkLoginPane = synchronize.text?.linkLoginPane {
                return Promise(value: linkLoginPane)
            } else {
                return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "no linkLoginPane data attached"))
            }
        }
    }

    func lookup(emailAddress: String) -> Future<LookupConsumerSessionResponse> {
        return apiClient.consumerSessionLookup(emailAddress: emailAddress, clientSecret: clientSecret)
    }

    func signUp(
        emailAddress: String,
        phoneNumber: String,
        country: String
    ) -> Future<LinkSignUpResponse> {
        apiClient.linkAccountSignUp(
            emailAddress: emailAddress,
            phoneNumber: phoneNumber,
            country: country
        )
    }

    func attachToAccountAndSynchronize(
        with linkSignUpResponse: LinkSignUpResponse
    ) -> Future<FinancialConnectionsSynchronize> {
        attachLinkConsumerToLinkAccountSessionResponse(
            linkAccountSession: clientSecret,
            consumerSessionClientSecret: linkSignUpResponse.consumerSession.clientSecret
        )
        .chained { [weak self] _ in
            guard let self else {
                return Promise(error: Self.deallocatedError)
            }

            return apiClient.synchronize(
                clientSecret: self.clientSecret,
                returnURL: self.returnURL
            )
        }
    }

    private func attachLinkConsumerToLinkAccountSessionResponse(
        linkAccountSession: String,
        consumerSessionClientSecret: String
    ) -> Future<AttachLinkConsumerToLinkAccountSessionResponse> {
        apiClient.attachLinkConsumerToLinkAccountSession(
            linkAccountSession: linkAccountSession,
            consumerSessionClientSecret: consumerSessionClientSecret
        )
    }
}
