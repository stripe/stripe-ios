//
//  FCLiteErrorView.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-19.
//

@_spi(STP) import StripeCore
import UIKit

class ErrorView: UIView {
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

        let errorLabel = UILabel()
        let errorLabelText = STPLocalizedString(
            "Failed to connect",
            "Label shown when a network-related error has occured."
        )
        errorLabel.text = errorLabelText
        errorLabel.textAlignment = .center
        errorLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false

        let retryButton = UIButton(type: .system)
        let retryButtonText = String.Localized.tryAgain
        retryButton.setTitle(retryButtonText, for: .normal)
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
