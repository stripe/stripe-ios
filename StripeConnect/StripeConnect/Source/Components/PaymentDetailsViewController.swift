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
    let webVC: ConnectComponentWebViewController

    public weak var delegate: PaymentDetailsViewControllerDelegate?

    init(componentManager: EmbeddedComponentManager) {
        weak var weakSelf: PaymentDetailsViewController?
        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .paymentDetails
        ) { error in
            guard let weakSelf else { return }
            weakSelf.delegate?.paymentDetails(weakSelf, didFailLoadWithError: error)
        }
        super.init(nibName: nil, bundle: nil)
        weakSelf = self

        addChild(webVC)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = webVC.view
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
