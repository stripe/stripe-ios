//
//  BlikExampleViewController.swift
//  Non-Card Payment Examples
//
//  Created by Eduardo Urias on 3/15/23.
//

import UIKit

public class BlikExampleViewController: UIViewController {
    @objc weak var delegate: ExampleViewControllerDelegate?
    var inProgress: Bool = false {
        didSet {
            navigationController?.navigationBar.isUserInteractionEnabled = !inProgress
            payButton.isEnabled = !inProgress
            inProgress
                ? activityIndicatorView.startAnimating() : activityIndicatorView.stopAnimating()
        }
    }

    // UI
    lazy var activityIndicatorView = {
        return UIActivityIndicatorView(style: .medium)
    }()
    lazy var payButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("Pay with BLIK", for: .normal)
        button.addTarget(self, action: #selector(didTapPayButton), for: .touchUpInside)
        return button
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "BLIK"
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
        guard STPAPIClient.shared.publishableKey != nil else {
            delegate?.exampleViewController(
                self,
                didFinishWithMessage: "Please set a Stripe Publishable Key in Constants.m"
            )
            return
        }
        inProgress = true
        pay()
    }
}

// MARK: -
extension BlikExampleViewController {
    @objc func pay() {
        // 1. Create a BLIK PaymentIntent
        MyAPIClient.shared().createPaymentIntent(
            completion: { (_, clientSecret, error) in
                guard let clientSecret = clientSecret else {
                    self.delegate?.exampleViewController(self, didFinishWithError: error)
                    return
                }

                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
                    blik: STPPaymentMethodBLIKParams(),
                    billingDetails: nil,
                    metadata: nil
                )
                paymentIntentParams.returnURL = "payments-example://safepay/"

                let blikOptions = STPConfirmBLIKOptions(code: "777123")
                let confirmPaymentMethodOptions = STPConfirmPaymentMethodOptions()
                confirmPaymentMethodOptions.blikOptions = blikOptions
                paymentIntentParams.paymentMethodOptions = confirmPaymentMethodOptions

                STPPaymentHandler.shared().confirmPayment(
                    paymentIntentParams,
                    with: self
                ) { (status, _, error) in
                    switch status {
                    case .canceled:
                        self.delegate?.exampleViewController(
                            self,
                            didFinishWithMessage: "Cancelled"
                        )
                    case .failed:
                        self.delegate?.exampleViewController(self, didFinishWithError: error)
                    case .succeeded:
                        self.delegate?.exampleViewController(
                            self,
                            didFinishWithMessage: "Payment successfully created."
                        )
                    @unknown default:
                        fatalError()
                    }
                }
            },
            additionalParameters: "supported_payment_methods=blik&country=pl&currency=pln"
        )
    }
}

extension BlikExampleViewController: STPAuthenticationContext {
    public func authenticationPresentingViewController() -> UIViewController {
        self
    }
}
