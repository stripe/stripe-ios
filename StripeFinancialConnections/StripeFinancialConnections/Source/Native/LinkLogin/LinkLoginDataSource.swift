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

    func synchronize() async throws -> FinancialConnectionsLinkLoginPane
    func lookup(emailAddress: String, manuallyEntered: Bool) async throws -> LookupConsumerSessionResponse
    func signUp(
        emailAddress: String,
        phoneNumber: String,
        country: String
    ) async throws -> LinkSignUpResponse
    func attachToAccountAndSynchronize(
        with linkSignUpResponse: LinkSignUpResponse
    ) async throws -> FinancialConnectionsSynchronize
    @discardableResult
    func completeAssertionIfNeeded(
        possibleError: Error?,
        api: FinancialConnectionsAPIClientLogger.API
    ) -> Error?}

final class LinkLoginDataSourceImplementation: LinkLoginDataSource {
    let manifest: FinancialConnectionsSessionManifest
    let elementsSessionContext: ElementsSessionContext?
    let analyticsClient: FinancialConnectionsAnalyticsClient

    private let clientSecret: String
    private let returnURL: String?
    private let apiClient: any FinancialConnectionsAsyncAPI

    init(
        manifest: FinancialConnectionsSessionManifest,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        clientSecret: String,
        returnURL: String?,
        apiClient: any FinancialConnectionsAsyncAPI,
        elementsSessionContext: ElementsSessionContext?
    ) {
        self.manifest = manifest
        self.analyticsClient = analyticsClient
        self.clientSecret = clientSecret
        self.returnURL = returnURL
        self.apiClient = apiClient
        self.elementsSessionContext = elementsSessionContext
    }

    func synchronize() async throws -> FinancialConnectionsLinkLoginPane {
        let synchronize = try await apiClient.synchronize(
            clientSecret: clientSecret,
            returnURL: returnURL,
            initialSynchronize: false
        )

        if let linkLoginPane = synchronize.text?.linkLoginPane {
            return linkLoginPane
        } else {
            throw FinancialConnectionsSheetError.unknown(debugDescription: "no linkLoginPane data attached")
        }
    }

    func lookup(emailAddress: String, manuallyEntered: Bool) async throws -> LookupConsumerSessionResponse {
        try await apiClient.consumerSessionLookup(
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
    ) async throws -> LinkSignUpResponse {
        try await apiClient.linkAccountSignUp(
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
    ) async throws -> FinancialConnectionsSynchronize {
        _ = try await apiClient.attachLinkConsumerToLinkAccountSession(
            linkAccountSession: clientSecret,
            consumerSessionClientSecret: linkSignUpResponse.consumerSession.clientSecret
        )

        return try await apiClient.synchronize(
            clientSecret: clientSecret,
            returnURL: returnURL,
            initialSynchronize: false
        )
    }

    // Marks the assertion as completed and logs possible errors during verified flows.
    @discardableResult
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
