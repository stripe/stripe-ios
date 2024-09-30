//
//  EmbeddedPlaygroundViewController.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 9/4/24.
//

import Foundation
@_spi(EmbeddedPaymentElementPrivateBeta) import StripePaymentSheet
import UIKit

protocol EmbeddedPlaygroundViewControllerDelegate: AnyObject {
    func didComplete(with result: PaymentSheetResult)
}

class EmbeddedPlaygroundViewController: UIViewController {

    private let settings: PaymentSheetTestPlaygroundSettings
    private let appearance: PaymentSheet.Appearance

    weak var delegate: EmbeddedPlaygroundViewControllerDelegate?

    private lazy var checkoutButton: UIButton = {
        let checkoutButton = UIButton(type: .system)
        checkoutButton.backgroundColor = appearance.primaryButton.backgroundColor ?? appearance.colors.primary
        checkoutButton.layer.cornerRadius = 5.0
        checkoutButton.clipsToBounds = true
        checkoutButton.setTitle("Checkout", for: .normal)
        checkoutButton.setTitleColor(.white, for: .normal)
        checkoutButton.translatesAutoresizingMaskIntoConstraints = false
        return checkoutButton
    }()

    init(settings: PaymentSheetTestPlaygroundSettings, appearance: PaymentSheet.Appearance) {
        self.settings = settings
        self.appearance = appearance
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(dynamicProvider: { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .secondarySystemBackground
            }

            return .systemBackground
        })

        // TODO: pass in an embedded configuration built from `PaymentSheetTestPlaygroundSettings`
        let paymentMethodsView = EmbeddedPaymentMethodsView(savedPaymentMethod: settings.customerMode == .returning ? .mockPaymentMethod : nil,
                                                            appearance: appearance,
                                                            shouldShowApplePay: settings.applePayEnabled == .on,
                                                            shouldShowLink: settings.linkMode == .link_pm)
        paymentMethodsView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(paymentMethodsView)
        self.view.addSubview(checkoutButton)

        NSLayoutConstraint.activate([
            paymentMethodsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            paymentMethodsView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            paymentMethodsView.widthAnchor.constraint(equalTo: view.widthAnchor),
            checkoutButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            checkoutButton.heightAnchor.constraint(equalToConstant: 50),
            checkoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            checkoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }
}

extension STPPaymentMethod {
    static var mockPaymentMethod: STPPaymentMethod? {
        let amex =
            [
                "card": [
                    "id": "preloaded_amex",
                    "exp_month": "10",
                    "exp_year": "2020",
                    "last4": "0005",
                    "brand": "amex",
                ],
                "type": "card",
                "id": "preloaded_amex",
            ] as [String: Any]
        return STPPaymentMethod.decodedObject(fromAPIResponse: amex)
    }
}
