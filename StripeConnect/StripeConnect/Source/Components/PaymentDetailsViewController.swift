//
//  PaymentDetailsViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 8/30/24.
//

import UIKit

/**
 Show details of a given payment and allow users to manage disputes and perform refunds.
 */
@_spi(DashboardOnly)
@available(iOS 15, *)
public class PaymentDetailsViewController: UIViewController {
    private(set) var webVC: ConnectComponentWebViewController!

    public weak var delegate: PaymentDetailsViewControllerDelegate?

    init(componentManager: EmbeddedComponentManager,
         loadContent: Bool,
         analyticsClientFactory: ComponentAnalyticsClientFactory) {
        super.init(nibName: nil, bundle: nil)
        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .paymentDetails,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory
        ) { [weak self] error in
            guard let self else { return }
            delegate?.paymentDetails(self, didFailLoadWithError: error)
        }

        addChildAndPinView(webVC)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setPayment(id: String) {
        webVC.sendMessage(CallSetterWithSerializableValueSender(payload: .init(
            setter: "setPayment",
            value: id
        )))
    }
}

/// Delegate of an `PaymentDetailsViewController`
@available(iOS 15, *)
@_spi(DashboardOnly)
public protocol PaymentDetailsViewControllerDelegate: AnyObject {

    /**
     Triggered when an error occurs loading the payment details component
     - Parameters:
       - paymentDetails: The payment details component that errored when loading
       - error: The error that occurred when loading the component
     */
    func paymentDetails(_ paymentDetails: PaymentDetailsViewController,
                        didFailLoadWithError error: Error)

}

@available(iOS 15, *)
public extension PaymentDetailsViewControllerDelegate {
    // Default implementation to make optional
    func paymentDetails(_ paymentDetails: PaymentDetailsViewController,
                        didFailLoadWithError error: Error) { }
}
