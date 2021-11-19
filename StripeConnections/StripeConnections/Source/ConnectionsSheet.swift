//
//  ConnectionsSheet.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/10/21.
//

import UIKit

final public class ConnectionsSheet {
    
    // MARK: - Types
    
    @frozen public enum ConnectionsResult {
        // User completed the connections session
        case completed(linkedAccountSession: LinkedAccountSession)
        // Failed with error
        case failed(error: ConnectionsSheetError)
        // User canceled out of the connections session
        case canceled
    }
    
    // MARK: - Properties
    
    public let linkAccountSessionClientSecret: String
    
    /// Completion block called when the sheet is closed or fails to open
    private var completion: ((ConnectionsResult) -> Void)?

  
    // MARK: - Init
    
    public init(linkAccountSessionClientSecret: String) {
        self.linkAccountSessionClientSecret = linkAccountSessionClientSecret
    }

    // MARK: - Public
    
    public func present(from presentingViewController: UIViewController,
                        completion: @escaping (ConnectionsResult) -> ()) {
        // Overwrite completion closure to retain self until called
        let completion: (ConnectionsResult) -> Void = { result in
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
            completion(.failed(error: error))
            return
        }
        
        let url = URL(string: "https://auth.stripe.com/link-accounts#clientSecret=\(linkAccountSessionClientSecret)")!
        let connectionsWebViewController = ConnectionsWebViewController(initialURL: url)
        presentingViewController.present(connectionsWebViewController, animated: true)
        connectionsWebViewController.load()
    }

}
