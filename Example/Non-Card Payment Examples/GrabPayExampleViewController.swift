//
//  GrabPayExampleViewController.swift
//  Non-Card Payment Examples
//
//  Created by Yuki Tokuhiro on 7/22/20.
//  Copyright © 2020 Stripe. All rights reserved.
//

import UIKit
import Stripe

/**
 An example of accepting GrabPay payments.
 
 See https://stripe.com/docs/payments/grabpay/accept-a-payment
 */
class GrabPayExampleViewController: UIViewController {
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
        button.setTitle("Pay with GrabPay", for: .normal)
        button.addTarget(self, action: #selector(didTapPayButton), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "GrabPay"
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

    @objc func didTapPayButton(sender: UIButton) {
        inProgress = true

        let grabPayParams = STPPaymentMethodGrabPayParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Chiaki"
        billingDetails.email = "email@email.com"

        let paymentMethodParams = STPPaymentMethodParams(grabPay: grabPayParams, billingDetails: billingDetails, metadata: nil)

        MyAPIClient.shared().createPaymentIntent(completion: { (_, clientSecret, error) in
            guard let clientSecret = clientSecret else {
                self.delegate?.exampleViewController(self, didFinishWithError: error)
                return
            }

            let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
            paymentIntentParams.paymentMethodParams = paymentMethodParams
            paymentIntentParams.returnURL = "payments-example://stripe-redirect"

            STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: self) { (status, _, error) in
                switch status {
                case .canceled:
                    self.delegate?.exampleViewController(self, didFinishWithMessage: "Canceled.")
                    return
                case .failed:
                    self.delegate?.exampleViewController(self, didFinishWithMessage: "Payment failed. \(String(describing: error?.localizedDescription))")
                    return
                case .succeeded:
                    self.delegate?.exampleViewController(self, didFinishWithMessage: "Your order was received and is awaiting payment confirmation.")
                @unknown default:
                    fatalError()
                }
            }
        }, additionalParameters: "country=sg")
    }
}

// MARK: -
extension GrabPayExampleViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        self
    }
}
