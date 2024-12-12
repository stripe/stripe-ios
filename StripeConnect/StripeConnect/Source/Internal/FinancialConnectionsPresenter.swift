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
        financialConnectionsSheet.apiClient = apiClient.makeCopy()
        financialConnectionsSheet.apiClient.stripeAccount = connectedAccountId
        return await withCheckedContinuation { continuation in
            financialConnectionsSheet.presentForToken(from: presentingViewController) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
