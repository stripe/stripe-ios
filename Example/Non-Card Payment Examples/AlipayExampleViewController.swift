//
//  AlipayExampleViewController.swift
//  Non-Card Payment Examples
//
//  Created by Yuki Tokuhiro on 9/16/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit
import Stripe

class AlipayExampleViewController: UIViewController {
    @objc weak var delegate: ExampleViewControllerDelegate?
    var inProgress: Bool = false {
        didSet {
            navigationController?.navigationBar.isUserInteractionEnabled = !inProgress
            payButton.isEnabled = !inProgress
            inProgress ? activityIndicatorView.startAnimating() : activityIndicatorView.stopAnimating()
        }
    }

    // UI
    lazy var activityIndicatorView = {
       return UIActivityIndicatorView(style: .gray)
    }()
    lazy var payButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("Pay with Alipay", for: .normal)
        button.addTarget(self, action: #selector(didTapPayButton), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Alipay"
        [payButton, activityIndicatorView].forEach { subview in
            view.addSubview(subview)
            subview.translatesAutoresizingMaskIntoConstraints = false
        }

        let constraints = [
            payButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            payButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    @objc func didTapPayButton() {
        guard StripeAPI.defaultPublishableKey != nil else {
            delegate?.exampleViewController(self, didFinishWithMessage: "Please set a Stripe Publishable Key in Constants.m")
            return
        }
        inProgress = true
        pay()
    }
}

// MARK: -
extension AlipayExampleViewController {
    @objc func pay() {
        // 1. Create an Alipay PaymentIntent
        MyAPIClient.shared().createPaymentIntent(completion: { (_, clientSecret, error) in
            guard let clientSecret = clientSecret else {
                self.delegate?.exampleViewController(self, didFinishWithError: error)
                return
            }

            // 2. Redirect your customer to Alipay.
            // If the customer has the Alipay app installed, we open it.
            // Otherwise, we open alipay.com.
            let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
            paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(alipay: STPPaymentMethodAlipayParams(), billingDetails: nil, metadata: nil)
            paymentIntentParams.paymentMethodOptions = STPConfirmPaymentMethodOptions()
            paymentIntentParams.paymentMethodOptions?.alipayOptions = STPConfirmAlipayOptions()
            paymentIntentParams.returnURL = "payments-example://safepay/"

            STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: self) { (status, _, error) in
                switch status {
                case .canceled:
                    self.delegate?.exampleViewController(self, didFinishWithMessage: "Cancelled")
                case .failed:
                    self.delegate?.exampleViewController(self, didFinishWithError: error)
                case .succeeded:
                    self.delegate?.exampleViewController(self, didFinishWithMessage: "Payment successfully created.")
                @unknown default:
                    fatalError()
                }
            }
        }, additionalParameters: nil)
    }
}

extension AlipayExampleViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        self
    }
}
