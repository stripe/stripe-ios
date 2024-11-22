//
//  AccountManagementViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 9/21/24.
//

import UIKit

/**
 Show details of a given payment and allow users to manage disputes and perform refunds.
 */
@_spi(DashboardOnly)
@available(iOS 15, *)
public class AccountManagementViewController: UIViewController {

    struct Props: Encodable {
        let collectionOptions: AccountCollectionOptions

        enum CodingKeys: String, CodingKey {
            case collectionOptions = "setCollectionOptions"
        }
    }

    private(set) var webVC: ConnectComponentWebViewController!

    public weak var delegate: AccountManagementViewControllerDelegate?

    init(componentManager: EmbeddedComponentManager,
         collectionOptions: AccountCollectionOptions,
         loadContent: Bool,
         analyticsClientFactory: ComponentAnalyticsClientFactory) {
        super.init(nibName: nil, bundle: nil)
        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .accountManagement,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory
        ) {
            Props(collectionOptions: collectionOptions)
        } didFailLoadWithError: { [weak self] error in
            guard let self else { return }
            delegate?.accountManagement(self, didFailLoadWithError: error)
        }

        addChildAndPinView(webVC)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@_spi(DashboardOnly)
@available(iOS 15, *)
public protocol AccountManagementViewControllerDelegate: AnyObject {
    /**
     Triggered when an error occurs loading the account management component
     - Parameters:
       - accountManagement: The account management component that errored when loading
       - error: The error that occurred when loading the component
     */
    func accountManagement(_ accountManagement: AccountManagementViewController,
                           didFailLoadWithError error: Error)
}

@available(iOS 15, *)
public extension AccountManagementViewControllerDelegate {
    // Default implementation to make optional
    func accountManagement(_ accountManagement: AccountManagementViewController,
                           didFailLoadWithError error: Error) { }
}
