//
//  LinkController+SignupView.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 6/19/25.
//

import SwiftUI

extension LinkController {

    public struct SignupView: UIViewRepresentable {
        private let viewModel: LinkInlineSignupViewModel

        public init(viewModel: LinkInlineSignupViewModel) {
            self.viewModel = viewModel
        }

        public func makeUIView(context: Context) -> UIView {
            return LinkInlineSignupView(viewModel: viewModel)
        }

        public func updateUIView(_ uiView: UIView, context: Context) {
            // Nothing to do here.
        }
    }
}
