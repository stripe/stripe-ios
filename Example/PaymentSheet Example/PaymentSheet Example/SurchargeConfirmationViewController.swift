//
//  SurchargeConfirmationViewController.swift
//  PaymentSheet Example
//
//  Created for demonstration of surcharge confirmation flow
//

import UIKit

class SurchargeConfirmationViewController: UIViewController {

    private let originalAmount: Double
    private let surchargeAmount: Double
    private let totalAmount: Double
    private let onAccept: () -> Void
    private let onDecline: () -> Void

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Surcharge Applied"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "A surcharge has been calculated for your payment method."
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let breakdownStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let acceptButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Accept and Continue", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let declineButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel Payment", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }

    init(originalAmount: Double, surchargeAmount: Double, onAccept: @escaping () -> Void, onDecline: @escaping () -> Void) {
        self.originalAmount = originalAmount
        self.surchargeAmount = surchargeAmount
        self.totalAmount = originalAmount + surchargeAmount
        self.onAccept = onAccept
        self.onDecline = onDecline
        super.init(nibName: nil, bundle: nil)

        // Present as modal
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        setupUI()
        setupActions()
    }

    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(breakdownStackView)
        containerView.addSubview(acceptButton)
        containerView.addSubview(declineButton)

        // Add breakdown rows
        addBreakdownRow(label: "Original Amount", amount: originalAmount, isBold: false)
        addBreakdownRow(label: "Surcharge", amount: surchargeAmount, isBold: false, color: .systemOrange)

        // Add divider
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        breakdownStackView.addArrangedSubview(divider)
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])

        addBreakdownRow(label: "New Total", amount: totalAmount, isBold: true, fontSize: 20)

        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            breakdownStackView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            breakdownStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            breakdownStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            acceptButton.topAnchor.constraint(equalTo: breakdownStackView.bottomAnchor, constant: 32),
            acceptButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            acceptButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            acceptButton.heightAnchor.constraint(equalToConstant: 52),

            declineButton.topAnchor.constraint(equalTo: acceptButton.bottomAnchor, constant: 12),
            declineButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            declineButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            declineButton.heightAnchor.constraint(equalToConstant: 44),
            declineButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
        ])
    }

    private func addBreakdownRow(label: String, amount: Double, isBold: Bool, fontSize: CGFloat = 16, color: UIColor = .label) {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.distribution = .equalSpacing
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        let labelView = UILabel()
        labelView.text = label
        labelView.font = isBold ? .systemFont(ofSize: fontSize, weight: .bold) : .systemFont(ofSize: fontSize)
        labelView.textColor = color

        let amountLabel = UILabel()
        amountLabel.text = currencyFormatter.string(from: NSNumber(value: amount / 100))
        amountLabel.font = isBold ? .systemFont(ofSize: fontSize, weight: .bold) : .systemFont(ofSize: fontSize)
        amountLabel.textColor = color

        rowStack.addArrangedSubview(labelView)
        rowStack.addArrangedSubview(amountLabel)

        breakdownStackView.addArrangedSubview(rowStack)
    }

    private func setupActions() {
        acceptButton.addTarget(self, action: #selector(didTapAccept), for: .touchUpInside)
        declineButton.addTarget(self, action: #selector(didTapDecline), for: .touchUpInside)
    }

    @objc private func didTapAccept() {
        dismiss(animated: true) { [weak self] in
            self?.onAccept()
        }
    }

    @objc private func didTapDecline() {
        dismiss(animated: true) { [weak self] in
            self?.onDecline()
        }
    }
}
