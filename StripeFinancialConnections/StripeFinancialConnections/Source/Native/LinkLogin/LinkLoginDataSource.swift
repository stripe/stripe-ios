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
    var elementsSessionContext: ElementsSessionContext? { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func synchronize() -> Future<FinancialConnectionsLinkLoginPane>
    func lookup(emailAddress: String, manuallyEntered: Bool) -> Future<LookupConsumerSessionResponse>
    func signUp(
        emailAddress: String,
        phoneNumber: String,
        country: String
    ) -> Future<LinkSignUpResponse>
    func attachToAccountAndSynchronize(
        with linkSignUpResponse: LinkSignUpResponse
    ) -> Future<FinancialConnectionsSynchronize>
    func completeAssertionIfNeeded(
        possibleError: Error?,
        api: FinancialConnectionsAPIClientLogger.API
    ) -> Error?
}

final class LinkLoginDataSourceImplementation: LinkLoginDataSource {
    private static let deallocatedError = FinancialConnectionsSheetError.unknown(debugDescription: "data source deallocated")

    let manifest: FinancialConnectionsSessionManifest
    let elementsSessionContext: ElementsSessionContext?
    let analyticsClient: FinancialConnectionsAnalyticsClient

    private let clientSecret: String
    private let returnURL: String?
    private let apiClient: any FinancialConnectionsAPI

    init(
        manifest: FinancialConnectionsSessionManifest,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        clientSecret: String,
        returnURL: String?,
        apiClient: any FinancialConnectionsAPI,
        elementsSessionContext: ElementsSessionContext?
    ) {
        self.manifest = manifest
        self.analyticsClient = analyticsClient
        self.clientSecret = clientSecret
        self.returnURL = returnURL
        self.apiClient = apiClient
        self.elementsSessionContext = elementsSessionContext
    }

    func synchronize() -> Future<FinancialConnectionsLinkLoginPane> {
        apiClient.synchronize(
            clientSecret: clientSecret,
            returnURL: returnURL,
            initialSynchronize: false
        )
        .chained { synchronize in
            if let linkLoginPane = synchronize.text?.linkLoginPane {
                return Promise(value: linkLoginPane)
            } else {
                return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "no linkLoginPane data attached"))
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
            pane: .linkLogin
        )
    }

    func signUp(
        emailAddress: String,
        phoneNumber: String,
        country: String
    ) -> Future<LinkSignUpResponse> {
        return apiClient.linkAccountSignUp(
            emailAddress: emailAddress,
            phoneNumber: phoneNumber,
            country: country,
            amount: elementsSessionContext?.amount,
            currency: elementsSessionContext?.currency,
            incentiveEligibilitySession: elementsSessionContext?.incentiveEligibilitySession,
            useMobileEndpoints: manifest.verified,
            pane: .linkLogin
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
                returnURL: self.returnURL,
                initialSynchronize: false
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

    // Marks the assertion as completed and logs possible errors during verified flows.
    func completeAssertionIfNeeded(
        possibleError: Error?,
        api: FinancialConnectionsAPIClientLogger.API
    ) -> Error? {
        guard manifest.verified else { return nil }
        return apiClient.completeAssertion(
            possibleError: possibleError,
            api: api,
            pane: .linkLogin
        )
    }
}
