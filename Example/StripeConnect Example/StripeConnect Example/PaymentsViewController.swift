//
//  PaymentsViewController.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 4/28/24.
//

import UIKit
import StripeConnect

class PaymentsViewController: UIViewController {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var errorView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        STPAPIClient.shared.publishableKey = "pk_test_51MZRIlLirQdaQn8EJpw9mcVeXokTGaiV1ylz5AVQtcA0zAkoM9fLFN81yQeHYBLkCiID1Bj0sL1Ngzsq9ksRmbBN00O3VsIUdQ"
        let stripeConnectInstance = StripeConnectInstance(
            fetchClientSecret: fetchClientSecret
        )
        let paymentComponent = stripeConnectInstance.createPayments()
        containerView.addSubview(paymentComponent)
        
        paymentComponent.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            paymentComponent.topAnchor.constraint(equalTo: containerView.topAnchor),
            paymentComponent.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            paymentComponent.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            paymentComponent.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])
    }

    func fetchClientSecret() async -> String? {
        let url = URL(string: "https://stripe-connect-example.glitch.me/account_session")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            // Fetch the AccountSession client secret
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String : Any]

            errorView.isHidden = true
            containerView.isHidden = false

            return json?["client_secret"] as? String
        } catch {
            errorView.isHidden = false
            containerView.isHidden = true
            return nil
        }
    }
}
