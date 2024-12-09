//
//  ConsentDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/13/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol ConsentDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var consent: FinancialConnectionsConsent { get }
    var merchantLogo: [String]? { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func markConsentAcquired() -> Future<ConsentAcquiredResult>
}

struct ConsentAcquiredResult {
    var manifest: FinancialConnectionsSessionManifest
    var customNextPane: FinancialConnectionsSessionManifest.NextPane?
}

final class ConsentDataSourceImplementation: ConsentDataSource {

    let manifest: FinancialConnectionsSessionManifest
    let consent: FinancialConnectionsConsent
    let merchantLogo: [String]?
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    private let elementsSessionContext: ElementsSessionContext?
    
    private var isLinkWithStripe: Bool {
        manifest.isLinkWithStripe ?? false
    }

    init(
        manifest: FinancialConnectionsSessionManifest,
        consent: FinancialConnectionsConsent,
        merchantLogo: [String]?,
        apiClient: FinancialConnectionsAPIClient,
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
            let promise = Promise<ConsentAcquiredResult>()
            
            guard let self, self.isLinkWithStripe, self.manifest.accountholderCustomerEmailAddress == nil else {
                let result = ConsentAcquiredResult(manifest: manifest, customNextPane: nil)
                return Promise(value: result)
            }
            
            guard let email = elementsSessionContext?.prefillDetails?.email else {
                let result = ConsentAcquiredResult(manifest: manifest, customNextPane: nil)
                return Promise(value: result)
            }
            
            apiClient.consumerSessionLookup(
                emailAddress: email,
                clientSecret: clientSecret
            ).observe { lookupResult in
                let customNextPane = lookupResult.hasConsumer ? FinancialConnectionsSessionManifest.NextPane.networkingLinkLoginWarmup : nil
                let result = ConsentAcquiredResult(manifest: manifest, customNextPane: customNextPane)
                promise.resolve(with: result)
            }
            
            return promise
        }
    }
}

private extension Swift.Result<LookupConsumerSessionResponse, any Error> {
    
    var hasConsumer: Bool {
        switch self {
        case .success(let lookup):
            return lookup.exists
        case .failure:
            return false
        }
    }
}
