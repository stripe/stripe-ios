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

@available(iOSApplicationExtension, unavailable)
class ConsentFooterView: HitTestView {

    private let agreeButtonText: String
    private let didSelectAgree: () -> Void

    private lazy var agreeButton: StripeUICore.Button = {
        let agreeButton = Button(configuration: .financialConnectionsPrimary)
        agreeButton.title = agreeButtonText
        agreeButton.addTarget(self, action: #selector(didSelectAgreeButton), for: .touchUpInside)
        agreeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            agreeButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        return agreeButton
    }()

    init(
        aboveCtaText: String,
        ctaText: String,
        belowCtaText: String?,
        didSelectAgree: @escaping () -> Void,
        didSelectURL: @escaping (URL) -> Void
    ) {
        self.agreeButtonText = ctaText
        self.didSelectAgree = didSelectAgree
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor

        let termsAndPrivacyPolicyLabel = ClickableLabel(
            font: UIFont.stripeFont(forTextStyle: .detail),
            boldFont: UIFont.stripeFont(forTextStyle: .detailEmphasized),
            linkFont: UIFont.stripeFont(forTextStyle: .detailEmphasized),
            textColor: .textSecondary,
            alignCenter: true
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
        verticalStackView.spacing = 20

        if let belowCtaText = belowCtaText {
            let manuallyVerifyLabel = ClickableLabel(
                font: UIFont.stripeFont(forTextStyle: .detail),
                boldFont: UIFont.stripeFont(forTextStyle: .detailEmphasized),
                linkFont: UIFont.stripeFont(forTextStyle: .detailEmphasized),
                textColor: .textSecondary,
                alignCenter: true
            )
            manuallyVerifyLabel.setText(
                belowCtaText,
                action: didSelectURL
            )
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

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct ConsentFooterViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> ConsentFooterView {
        ConsentFooterView(
            aboveCtaText:
                "You agree to Stripe's [Terms](https://stripe.com/legal/end-users#linked-financial-account-terms) and [Privacy Policy](https://stripe.com/privacy). [Learn more](https://stripe.com/privacy-center/legal#linking-financial-accounts)",
            ctaText: "Agree",
            belowCtaText: "[Manually verify instead](https://www.stripe.com) (takes 1-2 business days)",
            didSelectAgree: {},
            didSelectURL: { _ in }
        )
    }

    func updateUIView(_ uiView: ConsentFooterView, context: Context) {
        uiView.sizeToFit()
    }
}

@available(iOSApplicationExtension, unavailable)
struct ConsentFooterView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack {
                ConsentFooterViewUIViewRepresentable()
                    .frame(maxHeight: 200)
                Spacer()
            }
            .padding()
        }
    }
}

#endif
