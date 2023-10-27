//
//  NetworkingLinkVerificationBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/9/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class NetworkingLinkVerificationBodyView: UIView {

    init(email: String, otpView: UIView) {
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                otpView,
                CreateEmailLabel(email: email),
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 20
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateEmailLabel(email: String) -> UIView {
    let emailLabel = AttributedLabel(
        font: .label(.medium),
        textColor: .textSecondary
    )
    emailLabel.text = String(format: STPLocalizedString("Signing in as %@", "A footnote that explains the user that when they enter an one-time-password code (OTP), they will be signing in as the email in this footnote. '%@' is replaced with an email, for examle: 'Signing in as user@gmail.com'."), email)
    return emailLabel
}

#if DEBUG

import SwiftUI

private struct NetworkingLinkVerificationBodyViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingLinkVerificationBodyView {
        NetworkingLinkVerificationBodyView(
            email: "test@stripe.com",
            otpView: UIView()
        )
    }

    func updateUIView(_ uiView: NetworkingLinkVerificationBodyView, context: Context) {}
}

struct NetworkingLinkVerificationBodyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            Spacer()
            NetworkingLinkVerificationBodyViewUIViewRepresentable()
                .frame(maxHeight: 100)
                .padding()
            Spacer()
        }
    }
}

#endif
