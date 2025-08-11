//
//  PaymentsViewController.swift
//  StripeConnect
//
//  Created by Torrance Yang on 7/16/25.
//

import UIKit

@_spi(DashboardOnly)
@available(iOS 15, *)
public class PaymentsViewController: UIViewController {

    struct Props: Encodable {
        let defaultFilters: EmbeddedComponentManager.PaymentsListDefaultFiltersOptions

        enum CodingKeys: String, CodingKey {
            case defaultFilters = "setDefaultFilters"
        }
    }

    private(set) var webVC: ConnectComponentWebViewController!

    public weak var delegate: PaymentsViewControllerDelegate?

    init(componentManager: EmbeddedComponentManager,
         loadContent: Bool,
         analyticsClientFactory: ComponentAnalyticsClientFactory,
         defaultFilters: EmbeddedComponentManager.PaymentsListDefaultFiltersOptions = .init()) {
        super.init(nibName: nil, bundle: nil)
        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .payments,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory
        ) {
            Props(defaultFilters: defaultFilters)
        } didFailLoadWithError: { [weak self] error in
            guard let self else { return }
            delegate?.payments(self, didFailLoadWithError: error)
        }

        addChildAndPinView(webVC)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Delegate of an `PaymentsViewController`
@_spi(DashboardOnly)
@available(iOS 15, *)
public protocol PaymentsViewControllerDelegate: AnyObject {

    /**
     Triggered when an error occurs loading the payments component
     - Parameters:
       - payments: The payments component that errored when loading
       - error: The error that occurred when loading the component
     */
    func payments(_ payments: PaymentsViewController,
                  didFailLoadWithError error: Error)

}

@available(iOS 15, *)
public extension PaymentsViewControllerDelegate {
    // Default implementation to make optional
    func payments(_ payments: PaymentsViewController,
                  didFailLoadWithError error: Error) { }
}
