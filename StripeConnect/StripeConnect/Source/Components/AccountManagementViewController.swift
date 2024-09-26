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
    let webView: ConnectComponentWebView

    public weak var delegate: AccountManagementViewControllerDelegate?

    init(componentManager: EmbeddedComponentManager,
         collectionOptions: AccountCollectionOptions) {
        webView = ConnectComponentWebView(
            componentManager: componentManager,
            componentType: .accountManagement
        )
        super.init(nibName: nil, bundle: nil)

        webView.addMessageHandler(OnLoadErrorMessageHandler { [weak self] value in
            guard let self else { return }
            self.delegate?.accountManagementLoadDidFail(self, withError: value.error.connectEmbedError)
        })

        // TODO(MXMOBILE-2796): Send collection options to web view

        webView.presentPopup = { [weak self] vc in
            self?.present(vc, animated: true)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = webView
    }
}

@_spi(DashboardOnly)
@available(iOS 15, *)
public protocol AccountManagementViewControllerDelegate: AnyObject {
    /**
     Triggered when an error occurs loading the payment details component
     - Parameters:
       - accountManagement: The payment details component that errored when loading
       - error: The error that occurred when loading the component
     */
    func accountManagementLoadDidFail(_ accountManagement: AccountManagementViewController,
                                      withError error: Error)
}

@available(iOS 15, *)
public extension AccountManagementViewControllerDelegate {
    // Default implementation to make optional
    func accountManagementLoadDidFail(_ accountManagement: AccountManagementViewController,
                                      withError error: Error) { }
}
