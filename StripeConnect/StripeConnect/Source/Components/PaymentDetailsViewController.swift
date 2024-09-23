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
    let webView: ConnectComponentWebView

    public weak var delegate: PaymentDetailsViewControllerDelegate?

    init(componentManager: EmbeddedComponentManager) {
        webView = ConnectComponentWebView(
            componentManager: componentManager,
            componentType: .paymentDetails
        )
        super.init(nibName: nil, bundle: nil)
        webView.addMessageHandler(OnLoadErrorMessageHandler { [weak self] value in
            guard let self else { return }
            self.delegate?.paymentDetailsLoadDidFail(self, withError: value.error.connectEmbedError)
        })
        // TODO: Add support for `setOnClose`
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

    public func setPayment(id: String) {
        webView.sendMessage(CallSetterWithSerializableValueSender(payload: .init(
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
    func paymentDetailsLoadDidFail(_ paymentDetails: PaymentDetailsViewController,
                                   withError error: Error)

}

@available(iOS 15, *)
public extension PaymentDetailsViewControllerDelegate {
    // Default implementation to make optional
    func paymentDetailsLoadDidFail(_ paymentDetails: PaymentDetailsViewController,
                                   withError error: Error) { }
}
