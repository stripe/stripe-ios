//
//  LinkController+SignupView.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 6/19/25.
//

import SwiftUI

@_spi(STP) import StripeUICore

extension LinkController {

    public struct SignupView: UIViewRepresentable {
        private let viewModel: LinkInlineSignupViewModel

        public init(viewModel: LinkInlineSignupViewModel) {
            self.viewModel = viewModel
        }

        public func makeUIView(context: Context) -> UIView {
            let containerView = UIView()
            containerView.backgroundColor = .clear
            containerView.layoutMargins = .zero

            let signupView = LinkInlineSignupView(viewModel: viewModel)
            let formView = FormView(
                viewModel: .init(
                    elements: [signupView],
                    bordered: viewModel.bordered,
                    theme: viewModel.configuration.appearance.asElementsTheme
                )
            )

            formView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(formView)

            NSLayoutConstraint.activate([
                formView.topAnchor.constraint(equalTo: containerView.topAnchor),
                formView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                formView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            ])

            return containerView
        }

        public func updateUIView(_ uiView: UIView, context: Context) {
            // Nothing to do here.
            print(uiView.frame)
        }
    }
}
