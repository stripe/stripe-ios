//
//  UIButton+StripeUICore.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 2/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) public extension UIButton {

    class var doneButtonTitle: String {
        return STPLocalizedString("Done", "Done button title")
    }
    
    class var editButtonTitle: String {
        return STPLocalizedString("Edit", "Button title to enter editing mode")
    }
    
    class func make(type buttonType: UIButton.ButtonType, didTap: @escaping () -> ()) -> UIButton {
        class ClosureButton: UIButton {
            var didTap: () -> () = {}
            public override init(frame: CGRect) {
                super.init(frame: frame)
                addTarget(self, action: #selector(didTapSelector), for: .touchUpInside)
            }
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            @objc func didTapSelector() {
               didTap()
            }
        }

        let button = ClosureButton(type: buttonType)
        button.didTap = didTap
        return button
    }
}

