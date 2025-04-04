//
//  ConsentDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/13/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol ConsentDataSource: AnyObject {
    var email: String? { get }
    var manifest: FinancialConnectionsSessionManifest { get }
    var consent: FinancialConnectionsConsent { get }
    var merchantLogo: [String]? { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func markConsentAcquired() async throws -> ConsentAcquiredResult
    func completeAssertionIfNeeded(
        possibleError: Error?,
        api: FinancialConnectionsAPIClientLogger.API
    ) -> Error?
}

struct ConsentAcquiredResult {
    var manifest: FinancialConnectionsSessionManifest
    var consumerSession: ConsumerSessionData?
    var consumerPublishableKey: String?

    var nextPane: FinancialConnectionsSessionManifest.NextPane {
        // If we have a consumer session, then provide the returning-user experience
        consumerSession != nil ? .networkingLinkLoginWarmup : manifest.nextPane
    }
}

final class ConsentDataSourceImplementation: ConsentDataSource {

    let manifest: FinancialConnectionsSessionManifest
    let consent: FinancialConnectionsConsent
    let merchantLogo: [String]?
    private let apiClient: any FinancialConnectionsAsyncAPI
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    private let elementsSessionContext: ElementsSessionContext?

    var email: String? {
        elementsSessionContext?.prefillDetails?.email
    }

    init(
        manifest: FinancialConnectionsSessionManifest,
        consent: FinancialConnectionsConsent,
        merchantLogo: [String]?,
        apiClient: any FinancialConnectionsAsyncAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        elementsSessionContext: ElementsSessionContext?
    ) {
        self.manifest = manifest
        self.consent = consent
        self.merchantLogo = merchantLogo
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        self.elementsSessionContext = elementsSessionContext
    }

    func markConsentAcquired() async throws -> ConsentAcquiredResult {
        let manifest = try await apiClient.markConsentAcquired(clientSecret: clientSecret)
        guard manifest.shouldLookupConsumerSession, let email else {
            return ConsentAcquiredResult(manifest: manifest)
        }

        do {
            let lookupResult = try await apiClient.consumerSessionLookup(
                emailAddress: email,
                clientSecret: clientSecret,
                sessionId: manifest.id,
                emailSource: .customerObject,
                useMobileEndpoints: manifest.verified,
                pane: .consent
            )

            let result = ConsentAcquiredResult(
                manifest: manifest,
                consumerSession: lookupResult.consumerSession,
                consumerPublishableKey: lookupResult.publishableKey
            )
            return result
        } catch {
            return ConsentAcquiredResult(manifest: manifest)
        }
    }

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

private extension FinancialConnectionsSessionManifest {
    var shouldLookupConsumerSession: Bool {
        isLinkWithStripe == true && accountholderCustomerEmailAddress == nil
    }
}
