//
//  ConnectionsSDKInterface.swift
//  StripeCore
//
//  Created by Vardges Avetisyan on 2/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) @frozen public enum FinancialConnectionsSDKResult {
    case completed(linkedBank: LinkedBank)
    case cancelled
    case failed(error: Error)
}

@_spi(STP) public protocol FinancialConnectionsSDKInterface {
    init()
    func presentFinancialConnectionsSheet(
        apiClient: STPAPIClient,
        clientSecret: String,
        returnURL: String?,
        from presentingViewController: UIViewController,
        completion: @escaping (FinancialConnectionsSDKResult) -> Void
    )
}

// MARK: - Types

@_spi(STP) public protocol LinkedBank {
    var sessionId: String { get }
    var accountId: String { get }
    var displayName: String? { get }
    var bankName: String? { get }
    var last4: String? { get }
    var instantlyVerified: Bool { get }
}
