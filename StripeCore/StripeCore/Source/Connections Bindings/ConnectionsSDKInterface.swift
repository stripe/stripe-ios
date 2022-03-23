//
//  ConnectionsSDKInterface.swift
//  StripeCore
//
//  Created by Vardges Avetisyan on 2/24/22.
//

import UIKit

@_spi(STP) public enum ConnectionsSDKResult {
    case completed
    case cancelled
    case failed(error: Error)
}

@_spi(STP) public protocol ConnectionsSDKInterface {
    init()
    func presentConnectionsSheet(clientSecret: String,
                                 from presentingViewController: UIViewController,
                                 completion: @escaping (ConnectionsSDKResult) -> ())
}
