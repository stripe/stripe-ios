//
//  CheckboxElement.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/15/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@_spi(STP) public final class CheckboxElement {
    public weak var delegate: ElementDelegate?
    public private(set) lazy var checkboxButton: CheckboxButton = {
        let checkbox = CheckboxButton(
            text: label,
            theme: theme
        )
        checkbox.addTarget(self, action: #selector(didToggleCheckbox), for: .touchUpInside)
        checkbox.isSelected = isSelectedByDefault
        return checkbox
    }()
    let label: String
    let isSelectedByDefault: Bool
    let theme: ElementsAppearance
    var didToggle: (Bool) -> Void
    @_spi(STP) public var isSelected: Bool {
        get {
            return checkboxButton.isSelected
        }
        set {
            checkboxButton.isSelected = newValue
        }
    }

    @objc func didToggleCheckbox() {
        didToggle(checkboxButton.isSelected)
        delegate?.didUpdate(element: self)
    }

    public init(
        theme: ElementsAppearance,
        label: String,
        isSelectedByDefault: Bool,
        didToggle: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.isSelectedByDefault = isSelectedByDefault
        self.theme = theme
        self.didToggle = didToggle ?? { _ in }
    }
}

/// :nodoc:
extension CheckboxElement: Element {
    public var collectsUserInput: Bool {
        true
    }

    public var view: UIView {
        return checkboxButton
    }
}

// MARK: - DebugDescription
extension CheckboxElement {
    public var debugDescription: String {
        return "<CheckboxElement: \(Unmanaged.passUnretained(self).toOpaque())>; label = \(label); isSelected = \(isSelected); validationState = \(validationState)"
    }
}
