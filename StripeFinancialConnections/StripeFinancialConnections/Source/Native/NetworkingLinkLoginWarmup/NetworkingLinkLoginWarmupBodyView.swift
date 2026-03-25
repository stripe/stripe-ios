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
    var borderLayer: CALayer?

    init(email: String) {
        super.init(frame: .zero)
        let emailView = CreateEmailView(email: email)
        self.borderLayer = emailView.layer
        addAndPinSubview(emailView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // CGColor's need to be manually updated when the system theme changes.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        borderLayer?.borderColor = FinancialConnectionsAppearance.Colors.borderNeutral.cgColor
    }
}

private func CreateEmailView(
    email: String
) -> UIView {

    let emailLabel = AttributedLabel(
        font: .body(.small),
        textColor: FinancialConnectionsAppearance.Colors.textDefault
    )
    emailLabel.setText(email)

    let horizontalStack = UIStackView(
        arrangedSubviews: [
            CreateAvatarView(email: email),
            emailLabel,
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
    horizontalStack.layer.borderColor = FinancialConnectionsAppearance.Colors.borderNeutral.cgColor
    horizontalStack.layer.borderWidth = 1
    horizontalStack.layer.cornerRadius = 12
    return horizontalStack
}

private func CreateAvatarView(email: String) -> UIView {
    // Always use Link-themed appearance for this avatar view.
    let appearance = FinancialConnectionsAppearance.link
    let diameter: CGFloat = 36

    let circleView = UIView()
    circleView.backgroundColor = appearance.colors.primary
    circleView.layer.cornerRadius = diameter / 2
    circleView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        circleView.heightAnchor.constraint(equalToConstant: diameter),
        circleView.widthAnchor.constraint(equalToConstant: diameter),
    ])

    let letterLabel = AttributedLabel(
        font: .body(.small),
        textColor: appearance.colors.primaryAccent
    )
    letterLabel.setText(String(email.uppercased().first ?? "E"))
    circleView.addSubview(letterLabel)
    letterLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        letterLabel.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
        letterLabel.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
    ])

    return circleView
}

#if DEBUG

import SwiftUI

private struct NetworkingLinkLoginWarmupBodyViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingLinkLoginWarmupBodyView {
        NetworkingLinkLoginWarmupBodyView(email: "test@stripe.com")
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
