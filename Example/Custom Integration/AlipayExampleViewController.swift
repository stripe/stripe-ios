//
//  AlipayExampleViewController.swift
//  Custom Integration
//
//  Created by Yuki Tokuhiro on 9/16/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit
import Stripe

enum PaymentStatus {
    case success
    case cancelled
    case failed(error: Error?)
}

class AlipayExampleViewController: UIViewController {
    @objc weak var delegate: ExampleViewControllerDelegate?
    var redirectContext: STPRedirectContext?
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
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc func didTapPayButton() {
        guard Stripe.defaultPublishableKey() != nil else {
            delegate?.exampleViewController(self, didFinishWithMessage: "Please set a Stripe Publishable Key in Constants.m")
            return;
        }
        inProgress = true
        pay()
    }
    
    func didFinishPayment(_ status: PaymentStatus) {
        inProgress = false
        switch status {
        case .success:
            delegate?.exampleViewController(self, didFinishWithMessage: "Your order succeeded!")
        case .cancelled:
            return
        case .failed(let error):
            delegate?.exampleViewController(self, didFinishWithError: error)
        }
    }
}

// MARK: -
extension AlipayExampleViewController {
    @objc func pay() {
        // 1. Create an Alipay Source.
        let sourceParams = STPSourceParams.alipayParams(withAmount: 100,
                                                        currency: "USD",
                                                        returnURL: "payments-example://safepay/")
        STPAPIClient.shared().createSource(with: sourceParams) { source, error in
            guard let source = source else {
                self.didFinishPayment(.failed(error: error))
                return
            }
            // 2. Redirect your customer to Alipay.
            // If the customer has the Alipay app installed, we open it.
            // Otherwise, we open alipay.com.
            self.redirectContext = STPRedirectContext(source: source) { sourceID, clientSecret, error in
                guard let clientSecret = clientSecret else {
                    self.didFinishPayment(.failed(error: error))
                    return
                }
                
                // 3. Poll your backend to show the customer their order status.
                // This step is ommitted in the example, as our backend does not track orders.
                self.delegate?.exampleViewController(self, didFinishWithMessage: "Your order was received and is awaiting payment confirmation.")
                
                // 4. On your backend, use webhooks to charge the Source and fulfill the order
            }
            self.redirectContext?.startRedirectFlow(from: self)
        }
    }
}
