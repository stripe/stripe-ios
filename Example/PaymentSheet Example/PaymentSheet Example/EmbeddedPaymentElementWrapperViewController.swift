//
//  EmbeddedPaymentElementWrapperViewController.swift
//  PaymentSheet Example
//
//  Created by George Birch on 5/12/25.
//

import StripePaymentSheet
import UIKit

class EmbeddedPaymentElementWrapperViewController: UIViewController {
    let embeddedPaymentElement: EmbeddedPaymentElement
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
       return UIScrollView()
    }()
    lazy var continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 5.0
        button.setTitle("Continue", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.lightGray, for: .disabled)
        button.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        return button
    }()
    let needsDismissal: () -> Void

    init(embeddedPaymentElement: EmbeddedPaymentElement, needsDismissal: @escaping () -> Void) {
        self.embeddedPaymentElement = embeddedPaymentElement
        self.needsDismissal = needsDismissal
        super.init(nibName: nil, bundle: nil)
        // MARK: - Set Embedded Payment Element properties
        self.embeddedPaymentElement.presentingViewController = self
        self.embeddedPaymentElement.delegate = self
        continueButton.isEnabled = embeddedPaymentElement.paymentOption != nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        let stackView = UIStackView(arrangedSubviews: [embeddedPaymentElement.view, continueButton])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 16
        stackView.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true

        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            continueButton.heightAnchor.constraint(equalToConstant: 40),
        ])

        // Nav bar
        title = "Choose your payment method"
        let closeButton = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeButtonTapped))
        navigationItem.leftBarButtonItem = closeButton
        self.view.backgroundColor = UIColor(dynamicProvider: { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .secondarySystemBackground
            }

            return .systemBackground
        })
    }

    @objc private func closeButtonTapped() {
        needsDismissal()
    }
    @objc private func continueButtonTapped() {
        needsDismissal()
    }
}

// MARK: - EmbeddedPaymentElementDelegate
extension EmbeddedPaymentElementWrapperViewController: EmbeddedPaymentElementDelegate {
    func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement) {
        // Lay out the scroll view that contains the Embedded Payment Element view
        scrollView.setNeedsLayout()
        scrollView.layoutIfNeeded()
    }

    func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {
        continueButton.isEnabled = embeddedPaymentElement.paymentOption != nil
    }
}
