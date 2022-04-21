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
            stack.customBackgroundColor = ElementsUITheme.current.colors.background
            stack.separatorColor = ElementsUITheme.current.colors.divider
            stack.borderColor = ElementsUITheme.current.colors.border
            stack.borderCornerRadius = ElementsUITheme.current.cornerRadius
            stack.spacing = ElementsUITheme.current.borderWidth
            stack.hideShadow = true
            stack.layer.applyShadow(shadow: ElementsUITheme.current.shadow)
            stack.axis = .vertical
            stack.distribution = .equalSpacing
        } else {
            let stack = UIStackView(arrangedSubviews: viewModel.elements)
            self.stackView = stack
            stack.axis = .vertical
            stack.spacing = ElementsUI.formSpacing
            stack.distribution = .equalSpacing
        }

        super.init(frame: .zero)
        addAndPinSubview(self.stackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setViews(_ views: [UIView], hidden: Bool, animated: Bool) {
        stackView.toggleArrangedSubviews(views, shouldShow: !hidden, animated: animated)
    }
}
