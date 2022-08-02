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
        public init(pickerDisplayName: String, labelDisplayName: String, accessibilityLabel: String, rawData: String) {
            self.pickerDisplayName = pickerDisplayName
            self.labelDisplayName = labelDisplayName
            self.accessibilityLabel = accessibilityLabel
            self.rawData = rawData
        }
        
        /// Item label displayed in the picker
        public let pickerDisplayName: String
        
        /// Item label displayed in inline label when item has been selected
        public let labelDisplayName: String
        
        /// Accessibility label to use when this is in the inline label
        public let accessibilityLabel: String
        
        /// The underlying data for this dropdown item.
        /// e.g., A country dropdown item might display "United States" but its `rawData` is "US".
        /// This is ignored by `DropdownFieldElement`, and is intended as a convenience to be used in conjunction with `selectedItem`
        public let rawData: String
    }

    // MARK: - Public properties
    weak public var delegate: ElementDelegate?
    public let items: [DropdownItem]
    public var selectedItem: DropdownItem {
        return items[selectedIndex]
    }
    public var selectedIndex: Int {
        didSet {
            updatePickerField()
        }
    }
    public var didUpdate: DidUpdateSelectedIndex?

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
            delegate: self,
            theme: theme
        )
        return pickerFieldView
    }()

    // MARK: - Private properties
    private let label: String?
    private let theme: ElementsUITheme
    private var previouslySelectedIndex: Int

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
        theme: ElementsUITheme = .default,
        didUpdate: DidUpdateSelectedIndex? = nil
    ) {
        assert(!items.isEmpty, "`items` must contain at least one item")

        self.label = label
        self.theme = theme
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
            updatePickerField()
        }
    }
    
    public func select(index: Int) {
        selectedIndex = index
        didFinish(pickerFieldView)
    }
}

private extension DropdownFieldElement {

    func updatePickerField() {
        if pickerView.selectedRow(inComponent: 0) != selectedIndex {
            pickerView.selectRow(selectedIndex, inComponent: 0, animated: false)
        }

        pickerFieldView.displayText = items[selectedIndex].labelDisplayName
        pickerFieldView.displayTextAccessibilityLabel = items[selectedIndex].accessibilityLabel
    }

}

// MARK: Element

extension DropdownFieldElement: Element {
    public var view: UIView {
        return pickerFieldView
    }
    
    public func beginEditing() -> Bool {
        return pickerFieldView.becomeFirstResponder()
    }
}

// MARK: UIPickerViewDelegate

extension DropdownFieldElement: UIPickerViewDelegate {
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return items[row].pickerDisplayName
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedIndex = row
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
        delegate?.continueToNextField(element: self)
    }
}
