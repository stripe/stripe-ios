//
//  NetworkingSaveToLinkBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/14/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class NetworkingSaveToLinkVerificationBodyView: UIView {

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
    emailLabel.text = String(format: STPLocalizedString("Signing in as %@", "A footnote that explains to the user that they are signing in as a user with a specific e-mail. '%@' is replaced with an e-mail, for example, 'Signing in as test@test.com'"), email)
    return emailLabel
}

#if DEBUG

import SwiftUI

private struct NetworkingSaveToLinkVerificationBodyViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingSaveToLinkVerificationBodyView {
        NetworkingSaveToLinkVerificationBodyView(
            email: "test@stripe.com",
            otpView: UIView()
        )
    }

    func updateUIView(_ uiView: NetworkingSaveToLinkVerificationBodyView, context: Context) {}
}

struct NetworkingSaveToLinkVerificationBodyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            Spacer()
            NetworkingSaveToLinkVerificationBodyViewUIViewRepresentable()
                .frame(maxHeight: 100)
                .padding()
            Spacer()
        }
    }
}

#endif
