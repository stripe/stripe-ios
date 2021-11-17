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
    
    // MARK: - Properties
    
    public let linkAccountSessionClientSecret: String
    
    /// Completion block called when the sheet is closed or fails to open
    private var completion: ((ConnectionsFlowResult) -> Void)?

  
    // MARK: - Init
    
    public init(linkAccountSessionClientSecret: String) {
        self.linkAccountSessionClientSecret = linkAccountSessionClientSecret
    }

    // MARK: - Public
    
    public func present(from presentingViewController: UIViewController,
                        completion: @escaping (ConnectionsFlowResult) -> ()) {
        // Overwrite completion closure to retain self until called
        let completion: (ConnectionsFlowResult) -> Void = { result in
            completion(result)
            self.completion = nil
        }
        self.completion = completion
        
        // Guard against basic user error
        guard presentingViewController.presentedViewController == nil else {
            assertionFailure("presentingViewController is already presenting a view controller")
            let error = ConnectionsSheetError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            completion(.failed(error: error, linkedAccountSession: nil))
            return
        }
        
        let connectionsFlowWebViewController = UIViewController(nibName: nil, bundle: nil)
        connectionsFlowWebViewController.view.backgroundColor = .red
        presentingViewController.present(connectionsFlowWebViewController, animated: true)
    }

}
