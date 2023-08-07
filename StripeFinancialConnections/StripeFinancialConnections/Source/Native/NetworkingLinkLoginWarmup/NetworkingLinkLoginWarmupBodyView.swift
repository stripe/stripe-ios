//
//  NetworkingLinkLoginWarmupBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/6/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class NetworkingLinkLoginWarmupBodyView: HitTestView {

    private let didSelectContinue: () -> Void

    init(
        email: String,
        didSelectContinue: @escaping (() -> Void),
        didSelectSkip: @escaping (() -> Void)
    ) {
        self.didSelectContinue = didSelectContinue
        super.init(frame: .zero)
        let verticalStackView = HitTestStackView(
            arrangedSubviews: [
                CreateContinueButton(
                    email: email,
                    didSelectContinue: didSelectContinue,
                    target: self
                ),
                CreateSkipButton(didSelectSkip: didSelectSkip),
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 20
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func didSelectContinueButton() {
        didSelectContinue()
    }
}

private func CreateContinueButton(
    email: String,
    didSelectContinue: @escaping () -> Void,
    target: UIView
) -> UIView {
    let horizontalStack = UIStackView(
        arrangedSubviews: [
            CreateContinueButtonLabelView(email: email),
            CreateArrowIconView(),
        ]
    )
    horizontalStack.axis = .horizontal
    horizontalStack.alignment = .center
    horizontalStack.spacing = 12
    horizontalStack.isLayoutMarginsRelativeArrangement = true
    horizontalStack.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 12,
        leading: 16,
        bottom: 12,
        trailing: 16
    )
    horizontalStack.layer.borderColor = UIColor.borderNeutral.cgColor
    horizontalStack.layer.borderWidth = 1
    horizontalStack.layer.cornerRadius = 4

    let tapGestureRecognizer = UITapGestureRecognizer(
        target: target,
        action: #selector(NetworkingLinkLoginWarmupBodyView.didSelectContinueButton)
    )
    horizontalStack.addGestureRecognizer(tapGestureRecognizer)

    return horizontalStack
}

private func CreateContinueButtonLabelView(email: String) -> UIView {
    let continueLabel = AttributedLabel(
        font: .label(.small),
        textColor: .textSecondary
    )
    continueLabel.text = STPLocalizedString(
        "Continue as",
        "Leading text that comes before an e-mail. For example, it might say 'Continue as username@gmail.com'. This text will be combined together to form a button which, when pressed, will automatically log-in the user with their e-mail."
    )

    let emailLabel = AttributedLabel(
        font: .label(.largeEmphasized),
        textColor: .textPrimary
    )
    emailLabel.text = email

    let verticalStackView = UIStackView(
        arrangedSubviews: [
            continueLabel,
            emailLabel,
        ]
    )
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 0
    return verticalStackView
}

private func CreateArrowIconView() -> UIView {
    let imageView = UIImageView(image: Image.arrow_right.makeImage(template: true))
    imageView.tintColor = .textBrand
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: 16),
        imageView.heightAnchor.constraint(equalToConstant: 16),
    ])
    return imageView
}

private func CreateSkipButton(
    didSelectSkip: @escaping () -> Void
) -> UIView {
    let leadingText = STPLocalizedString(
        "Not you?",
        "Leading text that comes before a button. For example, it will say 'Not you? Continue without signing in'. Pressing 'Continue without signing in' will allow the user to continue through the Bank Authentication Flow."
    )
    let continueButtonText = STPLocalizedString(
        "Continue without signing in",
        "Text for a butoon. Pressing it will allow the user to continue through the Bank Authentication Flow."
    )
    let skipLabel = AttributedTextView(
        font: .label(.medium),
        boldFont: .label(.mediumEmphasized),
        linkFont: .label(.mediumEmphasized),
        textColor: .textSecondary
    )
    skipLabel.setText(
        "\(leadingText) [\(continueButtonText)](stripe://no-url-action-handler-will-be-used)",
        action: { _ in
            didSelectSkip()
        }
    )
    return skipLabel
}

#if DEBUG

import SwiftUI

private struct NetworkingLinkLoginWarmupBodyViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingLinkLoginWarmupBodyView {
        NetworkingLinkLoginWarmupBodyView(
            email: "test@stripe.com",
            didSelectContinue: {},
            didSelectSkip: {}
        )
    }

    func updateUIView(_ uiView: NetworkingLinkLoginWarmupBodyView, context: Context) {}
}

struct NetworkingLinkLoginWarmupBodyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            Spacer()
            NetworkingLinkLoginWarmupBodyViewUIViewRepresentable()
                .frame(maxHeight: 200)
                .padding()
            Spacer()
        }
    }
}

#endif
