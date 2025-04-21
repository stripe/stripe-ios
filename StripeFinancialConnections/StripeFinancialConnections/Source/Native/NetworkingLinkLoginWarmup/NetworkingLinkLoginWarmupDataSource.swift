//
//  NetworkingLinkLoginWarmupDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/6/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkingLinkLoginWarmupDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var email: String? { get }
    var hasConsumerSession: Bool { get }

    func lookupConsumerSession() -> Future<LookupConsumerSessionResponse>
    func disableNetworking() -> Future<FinancialConnectionsSessionManifest>
    func completeAssertionIfNeeded(
        possibleError: Error?,
        api: FinancialConnectionsAPIClientLogger.API
    ) -> Error?
}

final class NetworkingLinkLoginWarmupDataSourceImplementation: NetworkingLinkLoginWarmupDataSource {

    let manifest: FinancialConnectionsSessionManifest
    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    private let nextPaneOrDrawerOnSecondaryCta: String?
    private let elementsSessionContext: ElementsSessionContext?

    var email: String? {
        manifest.accountholderCustomerEmailAddress ?? elementsSessionContext?.prefillDetails?.email
    }

    var hasConsumerSession: Bool {
        apiClient.consumerSession != nil && apiClient.consumerPublishableKey != nil
    }

    init(
        manifest: FinancialConnectionsSessionManifest,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        nextPaneOrDrawerOnSecondaryCta: String?,
        elementsSessionContext: ElementsSessionContext?
    ) {
        self.manifest = manifest
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        self.nextPaneOrDrawerOnSecondaryCta = nextPaneOrDrawerOnSecondaryCta
        self.elementsSessionContext = elementsSessionContext
    }

    func lookupConsumerSession() -> Future<LookupConsumerSessionResponse> {
        guard let email else {
            let error = FinancialConnectionsSheetError.unknown(debugDescription: "Unexpected nil email in warmup data source")
            analyticsClient.logUnexpectedError(
                error,
                errorName: "NoEmailInWarmupPaneError",
                pane: .networkingLinkLoginWarmup
            )
            return Promise(error: error)
        }
        return apiClient.consumerSessionLookup(
            emailAddress: email,
            clientSecret: clientSecret,
            sessionId: manifest.id,
            emailSource: .customerObject,
            useMobileEndpoints: manifest.verified,
            pane: .networkingLinkLoginWarmup
        )
    }

    func disableNetworking() -> Future<FinancialConnectionsSessionManifest> {
        return apiClient.disableNetworking(
            disabledReason: "returning_consumer_opt_out",
            clientSuggestedNextPaneOnDisableNetworking: nextPaneOrDrawerOnSecondaryCta,
            clientSecret: clientSecret
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
            pane: .networkingLinkLoginWarmup
        )
    }
}
