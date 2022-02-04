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
    
    public init(viewModel: FormElement.ViewModel) {
        super.init(frame: .zero)
        
        if viewModel.bordered {
            let stack = StackViewWithSeparator(arrangedSubviews: viewModel.elements)
            stack.drawBorder = true
            stack.separatorColor = InputFormColors.outlineColor
            stack.borderCornerRadius = 8
            stack.axis = .vertical
            stack.spacing = 1
            stack.distribution = .equalSpacing
            addAndPinSubview(stack)
        } else {
            let stack = UIStackView(arrangedSubviews: viewModel.elements)
            stack.axis = .vertical
            stack.spacing = 12
            stack.distribution = .equalSpacing
            addAndPinSubview(stack)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
