//
//  ConnectionsSheet.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/10/21.
//

import UIKit

final public class ConnectionsSheet {
    
    // MARK: - Types
    
    @frozen public enum ConnectionsFlowResult {
        // User completed the connections flow
        case completed(linkedAccountSession: LinkedAccountSession)
        // Failed with error
        case failed(error: ConnectionsSheetError, linkedAccountSession: LinkedAccountSession?)
        // User canceled out of the flow or declined to give consent
        case canceled(error: ConnectionsSheetError?, linkedAccountSession: LinkedAccountSession?)
    }
  
    // MARK: - Init
    
    public init(linkAccountSessionClientSecret: String) {
        
    }

    // MARK: - Public
    
    public func present(from presentingViewController: UIViewController,
                        completion: (ConnectionsFlowResult) -> ()) {
        
    }

}
