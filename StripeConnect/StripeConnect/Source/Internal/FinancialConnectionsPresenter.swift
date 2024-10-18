//
//  FinancialConnectionsPresenter.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/18/24.
//

import StripeFinancialConnections
import UIKit

/// Wraps `FinancialConnectionsSheet` for easy dependency injection in tests
class FinancialConnectionsPresenter {
    @MainActor
    func presentForToken(
        apiClient: STPAPIClient,
        clientSecret: String,
        from presentingViewController: UIViewController
    ) async -> FinancialConnectionsSheet.TokenResult {
        let financialConnectionsSheet = FinancialConnectionsSheet(
            financialConnectionsSessionClientSecret: clientSecret
        )
        financialConnectionsSheet.apiClient = apiClient
        return await withCheckedContinuation { continuation in
            financialConnectionsSheet.presentForToken(from: presentingViewController) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
