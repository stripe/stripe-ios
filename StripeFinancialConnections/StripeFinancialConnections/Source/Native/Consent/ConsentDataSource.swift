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

    func markConsentAcquired() -> Future<ConsentAcquiredResult>
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
    private let apiClient: any FinancialConnectionsAPI
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
        apiClient: any FinancialConnectionsAPI,
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

    func markConsentAcquired() -> Future<ConsentAcquiredResult> {
        return apiClient.markConsentAcquired(clientSecret: clientSecret).chained { [weak self] manifest in
            guard let self, manifest.shouldLookupConsumerSession, let email else {
                let result = ConsentAcquiredResult(manifest: manifest)
                return Promise(value: result)
            }

            let promise = Promise<ConsentAcquiredResult>()

            apiClient.consumerSessionLookup(
                emailAddress: email,
                clientSecret: clientSecret,
                sessionId: manifest.id,
                emailSource: .customerObject,
                useMobileEndpoints: manifest.verified,
                pane: .consent
            ).observe { lookupResult in
                switch lookupResult {
                case .success(let response):
                    let result = ConsentAcquiredResult(
                        manifest: manifest,
                        consumerSession: response.consumerSession,
                        consumerPublishableKey: response.publishableKey
                    )
                    promise.resolve(with: result)
                case .failure:
                    let result = ConsentAcquiredResult(manifest: manifest)
                    promise.resolve(with: result)
                }
            }

            return promise
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
