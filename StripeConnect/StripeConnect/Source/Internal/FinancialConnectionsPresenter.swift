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
    func presentForToken(
        apiClient: STPAPIClient,
        clientSecret: String,
        connectedAccountId: String,
        from presentingViewController: UIViewController
    ) async -> FinancialConnectionsSheet.TokenResult {
        let financialConnectionsSheet = FinancialConnectionsSheet(
            financialConnectionsSessionClientSecret: clientSecret
        )
        // FC needs the connected account ID to be configured on the API Client
        // Make a copy before modifying so we don't unexpectedly modify the shared API client
        financialConnectionsSheet.apiClient = apiClient.makeCopy()
        financialConnectionsSheet.apiClient.stripeAccount = connectedAccountId
        return await withCheckedContinuation { continuation in
            financialConnectionsSheet.presentForToken(from: presentingViewController) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
