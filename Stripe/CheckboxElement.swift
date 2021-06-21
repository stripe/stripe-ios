//
//  CheckboxElement.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/15/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

final class CheckboxElement {
    weak var delegate: ElementDelegate?
    lazy var checkboxButton: CheckboxButton = {
        let checkbox = CheckboxButton(
            text: STPLocalizedString(
                "Save for future payments",
                "The label of a switch indicating whether to save the payment method for future payments."
            )
        )
        checkbox.addTarget(self, action: #selector(didToggleCheckbox), for: .touchUpInside)
        checkbox.isSelected = true
        return checkbox
    }()
    let didToggle: (Bool) -> ()
    
    @objc func didToggleCheckbox() {
        didToggle(checkboxButton.isSelected)
        delegate?.didUpdate(element: self)
    }
    
    init(didToggle: ((Bool) -> ())? = nil) {
        self.didToggle = didToggle ?? {_ in}
    }
}

/// :nodoc:
extension CheckboxElement: Element {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        params.savePaymentMethod = checkboxButton.isSelected
        return params
    }
    
    var validationState: ElementValidationState {
        return .valid
    }
    
    var view: UIView {
        return checkboxButton
    }
}
