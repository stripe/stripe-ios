//
//  KlarnaExampleViewController.swift
//  Custom Integration
//
//  Created by David Estes on 10/28/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit
import Stripe

class KlarnaExampleViewController: UIViewController {
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
        button.setTitle("Pay with Klarna", for: .normal)
        button.addTarget(self, action: #selector(didTapPayButton), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Klarna"
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
}

// MARK: -
extension KlarnaExampleViewController {
    @objc func pay() {
        // 1. Create an Klarna Source.
        let sourceParams = STPSourceParams.klarnaParams(withAmount: 100, currency: "USD", returnURL: "payments-example://stripe-redirect", purchaseCountry: "US")
        STPAPIClient.shared().createSource(with: sourceParams) { source, error in
            guard let source = source else {
                self.delegate?.exampleViewController(self, didFinishWithError: error)
                return
            }
            // 2. Redirect your customer to Klarna.
            self.redirectContext = STPRedirectContext(source: source) { sourceID, clientSecret, error in
                guard let clientSecret = clientSecret else {
                    self.delegate?.exampleViewController(self, didFinishWithError: error)
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
