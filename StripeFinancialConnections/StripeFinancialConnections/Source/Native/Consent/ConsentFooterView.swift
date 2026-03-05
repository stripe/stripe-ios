//
//  ConsentFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/14/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class ConsentFooterView: HitTestView {

    private let agreeButtonText: String
    private let appearance: FinancialConnectionsAppearance
    private let didSelectAgree: () -> Void

    private lazy var agreeButton: StripeUICore.Button = {
        let agreeButton = Button.primary(appearance: appearance)
        agreeButton.title = agreeButtonText
        agreeButton.addTarget(self, action: #selector(didSelectAgreeButton), for: .touchUpInside)
        agreeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            agreeButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        agreeButton.accessibilityIdentifier = "consent_agree_button"
        return agreeButton
    }()

    init(
        aboveCtaText: String,
        ctaText: String,
        belowCtaText: String?,
        appearance: FinancialConnectionsAppearance,
        didSelectAgree: @escaping () -> Void,
        didSelectURL: @escaping (URL) -> Void
    ) {
        self.agreeButtonText = ctaText
        self.appearance = appearance
        self.didSelectAgree = didSelectAgree
        super.init(frame: .zero)
        backgroundColor = FinancialConnectionsAppearance.Colors.background

        let termsAndPrivacyPolicyLabel = AttributedTextView(
            font: .label(.small),
            boldFont: .label(.smallEmphasized),
            linkFont: .label(.small),
            textColor: FinancialConnectionsAppearance.Colors.textDefault,
            alignment: .center
        )
        termsAndPrivacyPolicyLabel.setText(
            aboveCtaText,
            action: didSelectURL
        )

        let verticalStackView = HitTestStackView(
            arrangedSubviews: [
                termsAndPrivacyPolicyLabel,
                agreeButton,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 16,
            leading: 24,
            bottom: 16,
            trailing: 24
        )

        if let belowCtaText = belowCtaText {
            let manuallyVerifyLabel = AttributedTextView(
                font: .label(.small),
                boldFont: .label(.smallEmphasized),
                linkFont: .label(.small),
                textColor: FinancialConnectionsAppearance.Colors.textDefault,
                alignment: .center
            )
            manuallyVerifyLabel.setText(
                belowCtaText,
                action: didSelectURL
            )
            manuallyVerifyLabel.accessibilityIdentifier = "consent_manually_verify_label"
            verticalStackView.addArrangedSubview(manuallyVerifyLabel)
            verticalStackView.setCustomSpacing(24, after: agreeButton)
        }

        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelectAgreeButton() {
        didSelectAgree()
    }

    func setIsLoading(_ isLoading: Bool) {
        agreeButton.isLoading = isLoading
    }
}
