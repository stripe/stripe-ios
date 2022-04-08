//
//  ConnectionsSDKImplementation.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 2/24/22.
//

import UIKit
@_spi(STP) import StripeCore

/**
 NOTE: If you change the name of this class, make sure to also change it ConnectionsSDKAvailability file
 */
@_spi(STP) public class ConnectionsSDKImplementation: ConnectionsSDKInterface {

    required public init() {}

    public func presentConnectionsSheet(clientSecret: String,
                                        from presentingViewController: UIViewController,
                                        completion: @escaping (ConnectionsSDKResult) -> ()) {
        let connectionsSheet = ConnectionsSheet(linkAccountSessionClientSecret: clientSecret)
        connectionsSheet.present(
            from: presentingViewController,
            completion: { result in
                switch result {
                case .completed(session: _):
                    completion(.completed)
                case .canceled:
                    completion(.cancelled)
                case .failed(let error):
                    completion(.failed(error: error))
                }
            })
    }

}
