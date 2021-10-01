//
//  DropdownFieldElement.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

/**
 A textfield whose input view is a `UIPickerView` with a list of the strings.
 */
@_spi(STP) public class DropdownFieldElement {
    public typealias DidUpdateSelectedIndex = (Int) -> Void

    weak public var delegate: ElementDelegate?
    lazy var dropdownView: DropdownFieldView = {
        return DropdownFieldView(
            items: items,
            defaultIndex: defaultIndex,
            label: label,
            delegate: self
        )
    }()
    let items: [String]
    let label: String
    let defaultIndex: Int
    public var selectedIndex: Int {
        return dropdownView.selectedRow
    }
    private var previouslySelectedIndex: Int
    public var didUpdate: DidUpdateSelectedIndex?

    public init(
        items: [String],
        defaultIndex: Int = 0,
        label: String,
        didUpdate: DidUpdateSelectedIndex? = nil
    ) {
        self.label = label
        self.items = items
        self.defaultIndex = defaultIndex
        self.previouslySelectedIndex = defaultIndex
        self.didUpdate = didUpdate
    }
}

// MARK: Element

extension DropdownFieldElement: Element {
    public var view: UIView {
        return dropdownView
    }
}

// MARK: - DropdownFieldDelegate

extension DropdownFieldElement: DropdownFieldViewDelegate {
    func didFinish(_ dropDownFieldView: DropdownFieldView) {
        if previouslySelectedIndex != selectedIndex {
            didUpdate?(selectedIndex)
        }
        previouslySelectedIndex = selectedIndex
        delegate?.didFinishEditing(element: self)
    }
}
