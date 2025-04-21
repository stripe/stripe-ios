//
//  FormView.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 A simple container view that displays its subviews in a vertical stack.
 
 For internal SDK use only
 */
@objc(STP_Internal_FormView)
@_spi(STP) public class FormView: UIView {
    private let stackView: UIStackView
    public init(viewModel: FormElement.ViewModel) {
        if viewModel.bordered {
            let stack = StackViewWithSeparator(arrangedSubviews: viewModel.elements)
            self.stackView = stack
            stack.drawBorder = true
            stack.customBackgroundColor = viewModel.theme.colors.componentBackground
            stack.separatorColor = viewModel.theme.colors.divider
            stack.borderColor = viewModel.theme.colors.border
            stack.borderCornerRadius = viewModel.theme.cornerRadius
            stack.spacing = viewModel.theme.borderWidth
            stack.hideShadow = true
            stack.layer.applyShadow(shadow: viewModel.theme.shadow)
            stack.axis = .vertical
        } else {
            let stack = UIStackView(arrangedSubviews: viewModel.elements)
            self.stackView = stack
            stack.axis = .vertical
            stack.spacing = ElementsUI.formSpacing
        }
        for (view, spacing) in viewModel.customSpacing {
            self.stackView.setCustomSpacing(spacing, after: view)
        }
        super.init(frame: .zero)
        addAndPinSubview(self.stackView)

        // When the form is empty, set a height constraint of zero with the lowest possible priority.
        // This provides a default height and avoids ambiguity in height constraints when there are no form elements present.
        let zeroConstraint = self.stackView.heightAnchor.constraint(equalToConstant: 0)
        zeroConstraint.priority = UILayoutPriority(rawValue: 1) // This sets the priority as low as possible, allowing other constraints to easily override it.
        NSLayoutConstraint.activate([
            zeroConstraint
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setViews(_ views: [UIView], hidden: Bool, animated: Bool) {
        stackView.toggleArrangedSubviews(views, shouldShow: !hidden, animated: animated)
    }
}
