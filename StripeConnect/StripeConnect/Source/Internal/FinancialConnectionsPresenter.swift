//
//  FinancialConnectionsPresenter.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/18/24.
//

@_spi(STP) import StripeCore
import StripeFinancialConnections
import UIKit

/// Wraps `FinancialConnectionsSheet` for easy dependency injection in tests
class FinancialConnectionsPresenter {

    @MainActor
    @available(iOS 15, *)
    func makeSheet(
        componentManager: EmbeddedComponentManager,
        clientSecret: String,
        connectedAccountId: String,
        from presentingViewController: UIViewController
    ) -> FinancialConnectionsSheet {
        let financialConnectionsSheet: FinancialConnectionsSheet = .init(financialConnectionsSessionClientSecret: clientSecret)
        // FC needs the connected account ID to be configured on the API Client
        // Make a copy before modifying so we don't unexpectedly modify the shared API client
        financialConnectionsSheet.apiClient = componentManager.apiClient.makeCopy()
        
        // FC expects a public key and not a UK. If there is a public key override we should use that.
        if let publicKeyOverride = componentManager.publicKeyOverride {
            financialConnectionsSheet.apiClient.publishableKey = publicKeyOverride
        }
        
        financialConnectionsSheet.apiClient.stripeAccount = connectedAccountId
        
        return financialConnectionsSheet
    }

    @MainActor
    @available(iOS 15, *)
    func presentForToken(
        componentManager: EmbeddedComponentManager,
        clientSecret: String,
        connectedAccountId: String,
        from presentingViewController: UIViewController
    ) async -> FinancialConnectionsSheet.TokenResult {
        let financialConnectionsSheet = makeSheet(componentManager: componentManager,
                                                  clientSecret: clientSecret,
                                                  connectedAccountId: connectedAccountId,
                                                  from: presentingViewController)
        return await withCheckedContinuation { continuation in
            financialConnectionsSheet.presentForToken(from: presentingViewController) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
