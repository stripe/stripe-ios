//
//  ErrorView.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-18.
//

import UIKit

class ErrorView: UIView {
    private let errorLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    var onRetryTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .white

        errorLabel.text = "Failed to connect"
        errorLabel.textAlignment = .center
        errorLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false

        retryButton.setTitle("Try again", for: .normal)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        retryButton.backgroundColor = FCLiteColor.stripe
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.layer.cornerRadius = 8
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        retryButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(errorLabel)
        addSubview(retryButton)

        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -40),

            retryButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 20),
            retryButton.widthAnchor.constraint(equalToConstant: 120),
            retryButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc private func retryButtonTapped() {
        onRetryTapped?()
    }
}
