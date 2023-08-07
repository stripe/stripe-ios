//
//  NetworkingSaveToLinkFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/15/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class NetworkingSaveToLinkFooterView: HitTestView {

    private let didSelectNotNow: () -> Void

    private lazy var buttonVerticalStack: UIStackView = {
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 12
        verticalStackView.addArrangedSubview(notNowButton)
        return verticalStackView
    }()

    private lazy var notNowButton: StripeUICore.Button = {
        let saveToLinkButton = Button(configuration: .financialConnectionsSecondary)
        saveToLinkButton.title = STPLocalizedString("Not now", "Title of a button that allows users to skip the current screen.")
        saveToLinkButton.addTarget(self, action: #selector(didSelectNotNowButton), for: .touchUpInside)
        saveToLinkButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            saveToLinkButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        return saveToLinkButton
    }()

    init(didSelectNotNow: @escaping () -> Void) {
        self.didSelectNotNow = didSelectNotNow
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor
        addAndPinSubview(buttonVerticalStack)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelectNotNowButton() {
        didSelectNotNow()
    }
}

#if DEBUG

import SwiftUI

private struct NetworkingSaveToLinkFooterViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingSaveToLinkFooterView {
        NetworkingSaveToLinkFooterView(
            didSelectNotNow: {}
        )
    }

    func updateUIView(_ uiView: NetworkingSaveToLinkFooterView, context: Context) {
        uiView.sizeToFit()
    }
}

@available(iOS 14.0, *)
struct NetworkingSaveToLinkFooterView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NetworkingSaveToLinkFooterViewUIViewRepresentable()
                .frame(maxHeight: 200)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

#endif
