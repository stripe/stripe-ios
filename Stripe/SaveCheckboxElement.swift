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
            text: label,
            appearance: appearance
        )
        checkbox.addTarget(self, action: #selector(didToggleCheckbox), for: .touchUpInside)
        checkbox.isSelected = isSelectedByDefault
        return checkbox
    }()
    let label: String
    let isSelectedByDefault: Bool
    let appearance: PaymentSheet.Appearance
    let didToggle: (Bool) -> ()
    
    @objc func didToggleCheckbox() {
        didToggle(checkboxButton.isSelected)
        delegate?.didUpdate(element: self)
    }
    
    init(
        appearance: PaymentSheet.Appearance,
        label: String,
        isSelectedByDefault: Bool,
        didToggle: ((Bool) -> ())? = nil
    ) {
        self.label = label
        self.isSelectedByDefault = isSelectedByDefault
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
