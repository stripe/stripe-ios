//
//  NetworkingLinkSignupFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/17/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class NetworkingLinkSignupFooterView: HitTestView {

    private let aboveCtaText: String
    private let saveToLinkButtonText: String
    private let notNowButtonText: String
    private let didSelectSaveToLink: () -> Void
    private let didSelectNotNow: () -> Void
    private let didSelectURL: (URL) -> Void

    private lazy var footerVerticalStackView: UIStackView = {
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 24
        verticalStackView.addArrangedSubview(aboveCtaLabel)
        verticalStackView.addArrangedSubview(buttonVerticalStack)
        return verticalStackView
    }()

    private lazy var aboveCtaLabel: AttributedTextView = {
        let termsAndPrivacyPolicyLabel = AttributedTextView(
            font: .body(.small),
            boldFont: .body(.smallEmphasized),
            linkFont: .body(.smallEmphasized),
            textColor: .textSecondary,
            alignCenter: true
        )
        termsAndPrivacyPolicyLabel.setText(
            aboveCtaText,
            action: didSelectURL
        )
        return termsAndPrivacyPolicyLabel
    }()

    private lazy var buttonVerticalStack: UIStackView = {
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 12
        verticalStackView.addArrangedSubview(notNowButton)
        return verticalStackView
    }()

    private lazy var saveToLinkButton: StripeUICore.Button = {
        let saveToLinkButton = Button(configuration: .financialConnectionsPrimary)
        saveToLinkButton.title = saveToLinkButtonText
        saveToLinkButton.addTarget(self, action: #selector(didSelectSaveToLinkButton), for: .touchUpInside)
        saveToLinkButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            saveToLinkButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        return saveToLinkButton
    }()

    private lazy var notNowButton: StripeUICore.Button = {
        let saveToLinkButton = Button(configuration: .financialConnectionsSecondary)
        saveToLinkButton.title = notNowButtonText
        saveToLinkButton.addTarget(self, action: #selector(didSelectNotNowButton), for: .touchUpInside)
        saveToLinkButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            saveToLinkButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        return saveToLinkButton
    }()

    init(
        aboveCtaText: String,
        saveToLinkButtonText: String,
        notNowButtonText: String,
        didSelectSaveToLink: @escaping () -> Void,
        didSelectNotNow: @escaping () -> Void,
        didSelectURL: @escaping (URL) -> Void
    ) {
        self.aboveCtaText = aboveCtaText
        self.saveToLinkButtonText = saveToLinkButtonText
        self.notNowButtonText = notNowButtonText
        self.didSelectSaveToLink = didSelectSaveToLink
        self.didSelectNotNow = didSelectNotNow
        self.didSelectURL = didSelectURL
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor
        addAndPinSubview(footerVerticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showSaveToLinkButtonIfNeeded() {
        guard saveToLinkButton.superview == nil else {
            return  // already added
        }
        notNowButton.removeFromSuperview()
        buttonVerticalStack.addArrangedSubview(saveToLinkButton)
        buttonVerticalStack.addArrangedSubview(notNowButton)
    }

    func enableSaveToLinkButton(_ enable: Bool) {
        saveToLinkButton.isEnabled = enable
    }

    @objc private func didSelectSaveToLinkButton() {
        didSelectSaveToLink()
    }

    @objc private func didSelectNotNowButton() {
        didSelectNotNow()
    }

    func setIsLoading(_ isLoading: Bool) {
        saveToLinkButton.isLoading = isLoading
    }
}

#if DEBUG

import SwiftUI

private struct NetworkingLinkSignupFooterViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingLinkSignupFooterView {
        NetworkingLinkSignupFooterView(
            aboveCtaText: "By saving your account to Link, you agree to Link’s [Terms](https://link.co/terms) and [Privacy Policy](https://link.co/privacy)",
            saveToLinkButtonText: "Save to Link",
            notNowButtonText: "Not now",
            didSelectSaveToLink: {},
            didSelectNotNow: {},
            didSelectURL: { _ in }
        )
    }

    func updateUIView(_ uiView: NetworkingLinkSignupFooterView, context: Context) {
        uiView.sizeToFit()
    }
}

@available(iOS 14.0, *)
struct NetworkingLinkSignupFooterView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NetworkingLinkSignupFooterViewUIViewRepresentable()
                .frame(maxHeight: 200)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

#endif
