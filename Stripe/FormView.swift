//
//  FormView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 A simple container view that displays its subviews in a vertical stack.
 */
class FormView: UIView {
    init(viewModel: FormElement.ViewModel) {
        super.init(frame: .zero)
        
        let stack = UIStackView(arrangedSubviews: viewModel.elements)
        stack.axis = .vertical
        stack.spacing = 16
        addAndPinSubview(stack)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
