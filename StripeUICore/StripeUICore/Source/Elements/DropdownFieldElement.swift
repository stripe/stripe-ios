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
 
 For internal SDK use only
 */
@objc(STP_Internal_DropdownFieldElement)
@_spi(STP) public class DropdownFieldElement: NSObject {
    public typealias DidUpdateSelectedIndex = (Int) -> Void
    
    public struct DropdownItem {
        /// Item label displayed in the picker
        let pickerDisplayName: String
        
        /// Item label displayed in inline label when item has been selected
        let labelDisplayName: String
        
        /// Accessibility label to use when this is in the inline label
        let accessibilityLabel: String
    }

    weak public var delegate: ElementDelegate?
    private(set) lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    private(set) lazy var pickerFieldView: PickerFieldView = {
        let pickerFieldView = PickerFieldView(
            label: label,
            shouldShowChevron: true,
            pickerView: pickerView,
            delegate: self
        )
        return pickerFieldView
    }()
    let items: [DropdownItem]
    let label: String?
    public private(set) var selectedIndex: Int
    private var previouslySelectedIndex: Int
    public var didUpdate: DidUpdateSelectedIndex?
    
    convenience public init(
        items: [String],
        defaultIndex: Int = 0,
        label: String?,
        didUpdate: DidUpdateSelectedIndex? = nil
    ) {
        let dropdownItems = items.map {
            DropdownItem(pickerDisplayName: $0, labelDisplayName: $0, accessibilityLabel: $0)
        }
        self.init(items: dropdownItems, defaultIndex: defaultIndex, label: label, didUpdate: didUpdate)
    }

    /**
     - Parameters:
       - items: Items to populate this dropdown with.
       - defaultIndex: Defaults the dropdown to the item with the corresponding index.
       - label: Label for the dropdown
       - didUpdate: Called when the user has finished selecting a new item.

     - Note:
       - Items must contain at least one item.
       - If `defaultIndex` is outside of the bounds of the `items` array, then a default of `0` is used.
       - `didUpdate` is not called if the user does not change their input before hitting "Done"
     */
    public init(
        items: [DropdownItem],
        defaultIndex: Int = 0,
        label: String?,
        didUpdate: DidUpdateSelectedIndex? = nil
    ) {
        assert(!items.isEmpty, "`items` must contain at least one item")

        self.label = label
        self.items = items
        self.didUpdate = didUpdate

        // Default to defaultIndex, if in bounds
        if defaultIndex < 0 || defaultIndex >= items.count {
            self.selectedIndex = 0
        } else {
            self.selectedIndex = defaultIndex
        }
        self.previouslySelectedIndex = selectedIndex
        super.init()

        if !items.isEmpty {
            pickerView.selectRow(defaultIndex, inComponent: 0, animated: false)
            pickerFieldView.displayText = items[selectedIndex].labelDisplayName
            pickerFieldView.displayTextAccessibilityLabel = items[selectedIndex].accessibilityLabel
        }
    }
}

// MARK: Element

extension DropdownFieldElement: Element {
    public var view: UIView {
        return pickerFieldView
    }
}

// MARK: UIPickerViewDelegate

extension DropdownFieldElement: UIPickerViewDelegate {
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return items[row].pickerDisplayName
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedIndex = row
        pickerFieldView.displayText = items[row].labelDisplayName
        pickerFieldView.displayTextAccessibilityLabel = items[selectedIndex].accessibilityLabel
    }
}

extension DropdownFieldElement: UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return items.count
    }
}

// MARK: - PickerFieldViewDelegate

extension DropdownFieldElement: PickerFieldViewDelegate {
    func didBeginEditing(_ pickerFieldView: PickerFieldView) {
        // No-op
    }

    func didFinish(_ pickerFieldView: PickerFieldView) {
        if previouslySelectedIndex != selectedIndex {
            didUpdate?(selectedIndex)
        }
        previouslySelectedIndex = selectedIndex
        delegate?.didFinishEditing(element: self)
    }
}
