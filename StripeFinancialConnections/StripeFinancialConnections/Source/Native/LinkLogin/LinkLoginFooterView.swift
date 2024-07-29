//
//  LinkLoginFooterView.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-07-25.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class LinkLoginFooterView: HitTestView {
    private let aboveCtaText: String
    private let cta: String
    private let theme: FinancialConnectionsTheme
    private let didSelectCta: () -> Void
    private let didSelectURL: (URL) -> Void

    private lazy var stackView: UIStackView = {
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 16,
            leading: 24,
            bottom: 16,
            trailing: 24
        )
        verticalStackView.addArrangedSubview(aboveCtaLabel)
        verticalStackView.addArrangedSubview(ctaButton)
        return verticalStackView
    }()

    private lazy var aboveCtaLabel: AttributedTextView = {
        let termsAndPrivacyPolicyLabel = AttributedTextView(
            font: .label(.small),
            boldFont: .label(.smallEmphasized),
            linkFont: .label(.small),
            textColor: .textDefault,
            alignCenter: true
        )
        termsAndPrivacyPolicyLabel.setText(
            aboveCtaText,
            action: didSelectURL
        )
        return termsAndPrivacyPolicyLabel
    }()

    private lazy var ctaButton: StripeUICore.Button = {
        let saveToLinkButton = Button.primary(theme: theme)
        saveToLinkButton.title = cta
        saveToLinkButton.addTarget(self, action: #selector(didSelectCtaButton), for: .touchUpInside)
        saveToLinkButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            saveToLinkButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        return saveToLinkButton
    }()

    init(
        aboveCtaText: String,
        cta: String,
        theme: FinancialConnectionsTheme,
        didSelectCta: @escaping () -> Void,
        didSelectURL: @escaping (URL) -> Void
    ) {
        self.aboveCtaText = aboveCtaText
        self.cta = cta
        self.theme = theme
        self.didSelectCta = didSelectCta
        self.didSelectURL = didSelectURL
        super.init(frame: .zero)
        addAndPinSubview(stackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelectCtaButton() {
        didSelectCta()
    }

    func enableCtaButton(_ enabled: Bool) {
        ctaButton.isEnabled = enabled
    }

    func setIsLoading(_ isLoading: Bool) {
        ctaButton.isLoading = isLoading
    }
}
