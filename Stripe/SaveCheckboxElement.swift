//
//  SaveCheckboxElement.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/15/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class SaveCheckboxElement {
    weak var delegate: ElementDelegate?
    lazy var checkboxButton: CheckboxButton = {
        let checkbox = CheckboxButton(
            text: STPLocalizedString(
                "Save for future payments",
                "The label of a switch indicating whether to save the payment method for future payments."
            ),
            appearance: appearance
        )
        checkbox.addTarget(self, action: #selector(didToggleCheckbox), for: .touchUpInside)
        checkbox.isSelected = true
        return checkbox
    }()
    let appearance: PaymentSheet.Appearance
    let didToggle: (Bool) -> ()
    
    @objc func didToggleCheckbox() {
        didToggle(checkboxButton.isSelected)
        delegate?.didUpdate(element: self)
    }
    
    init(appearance: PaymentSheet.Appearance, didToggle: ((Bool) -> ())? = nil) {
        self.appearance = appearance
        self.didToggle = didToggle ?? {_ in}
    }
}

/// :nodoc:
extension SaveCheckboxElement: Element {
    var view: UIView {
        return checkboxButton
    }
}
