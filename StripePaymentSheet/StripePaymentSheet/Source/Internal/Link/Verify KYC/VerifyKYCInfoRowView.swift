//
//  VerifyKYCInfoRowView.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 10/30/25.
//

import UIKit

@_spi(STP) import StripeUICore

/// Displays an individual KYC detail (e.g. name) with an optional edit button.
final class VerifyKYCInfoRowView: UIView {
    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [labelsStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.spacing = LinkUI.contentSpacing

        if editAction != nil {
            editButton.addTarget(self, action: #selector(didTapEdit), for: .touchUpInside)
            stackView.addArrangedSubview(editButton)
        }

        return stackView
    }()

    private lazy var labelsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = LinkUI.font(forTextStyle: .detail)
        label.textColor = .linkTextTertiary
        label.numberOfLines = 0
        return label
    }()

    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = LinkUI.font(forTextStyle: .body)
        label.textColor = .linkTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var editButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(Image.iconEditOutline.makeImage(), for: .normal)
        button.tintColor = .linkIconPrimary
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: LinkUI.minimumButtonHeight),
            button.heightAnchor.constraint(equalToConstant: LinkUI.minimumButtonHeight),
        ])
        return button
    }()

    private var editAction: (() -> Void)?

    /// Creates a new instance of `VerifyKYCInfoRowView`.
    /// - Parameters:
    ///   - title: The title of the info field to display.
    ///   - value: The user’s value of the info field to display.
    ///   - editAction: An optional action to call when the edit button is tapped. If `nil`, no edit button will be displayed.
    init(title: String, value: String, editAction: (() -> Void)? = nil) {
        self.editAction = editAction
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        valueLabel.text = value

        var insets = NSDirectionalEdgeInsets.insets(amount: LinkUI.contentSpacing)

        // Collapse the trailing inset if we're including the edit button.
        if editAction != nil {
            insets.trailing = 0
        }

        addAndPinSubview(containerStackView, insets: insets)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapEdit() {
        editAction?()
    }
}
