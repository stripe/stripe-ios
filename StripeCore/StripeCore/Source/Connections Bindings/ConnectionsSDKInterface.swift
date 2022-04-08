//
//  ConnectionsSDKInterface.swift
//  StripeCore
//
//  Created by Vardges Avetisyan on 2/24/22.
//

import UIKit

@_spi(STP) @frozen public enum ConnectionsSDKResult {
    case completed(linkedBank: LinkedBank)
    case cancelled
    case failed(error: Error)

    // MARK: - Types

    @_spi(STP) public struct LinkedBank {
        let sessionId: String
        let displayName: String?
        let bankName: String?
        let last4: String?
        let instantlyVerified: Bool

        public init(with sessionId: String,
                    displayName: String?,
                    bankName: String?,
                    last4: String?,
                    instantlyVerified: Bool) {
            self.sessionId = sessionId
            self.displayName = displayName
            self.bankName = bankName
            self.last4 = last4
            self.instantlyVerified = instantlyVerified
        }
    }
}

@_spi(STP) public protocol ConnectionsSDKInterface {
    init()
    func presentConnectionsSheet(clientSecret: String,
                                 from presentingViewController: UIViewController,
                                 completion: @escaping (ConnectionsSDKResult) -> ())
}
