//
//  DropdownFieldElement.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

/**
 A textfield whose input view is a `UIPickerView` (on iOS) or a `UIMenu` (on Catalyst) with a list of the strings.
 
 For internal SDK use only
 */
@objc(STP_Internal_DropdownFieldElement)
@_spi(STP) public class DropdownFieldElement: NSObject {
    public typealias DidUpdateSelectedIndex = (Int) -> Void

    public struct DropdownItem {
        public init(pickerDisplayName: NSAttributedString, labelDisplayName: NSAttributedString, accessibilityValue: String, rawData: String, isPlaceholder: Bool = false) {
            self.pickerDisplayName = pickerDisplayName
            self.labelDisplayName = labelDisplayName
            self.accessibilityValue = accessibilityValue
            self.isPlaceholder = isPlaceholder
            self.rawData = rawData
        }

        public init(pickerDisplayName: String, labelDisplayName: String, accessibilityValue: String, rawData: String, isPlaceholder: Bool = false) {
            self = .init(pickerDisplayName: NSAttributedString(string: pickerDisplayName),
                         labelDisplayName: NSAttributedString(string: labelDisplayName),
                         accessibilityValue: accessibilityValue,
                         rawData: rawData,
                         isPlaceholder: isPlaceholder)
        }

        /// Item label displayed in the picker
        public let pickerDisplayName: NSAttributedString

        /// Item label displayed in inline label when item has been selected
        public let labelDisplayName: NSAttributedString

        /// Accessibility value to use when this is in the inline label
        public let accessibilityValue: String

        /// The underlying data for this dropdown item.
        /// e.g., A country dropdown item might display "United States" but its `rawData` is "US".
        /// This is ignored by `DropdownFieldElement`, and is intended as a convenience to be used in conjunction with `selectedItem`
        public let rawData: String

        /// If true, this item will be styled with greyed out secondary text
        public let isPlaceholder: Bool
    }

    // MARK: - Public properties
    weak public var delegate: ElementDelegate?
    public private(set) var items: [DropdownItem]
    public var selectedItem: DropdownItem {
        return items[selectedIndex]
    }
    public var selectedIndex: Int {
        didSet {
            updatePickerField()
        }
    }
    public var didUpdate: DidUpdateSelectedIndex?
    public let theme: ElementsUITheme
    public let hasPadding: Bool

    /// A label displayed in the dropdown field UI e.g. "Country or region" for a country dropdown
    public let label: String?
#if targetEnvironment(macCatalyst)
    private(set) lazy var pickerView: UIButton = {
        let button = UIButton()
        let action = { (action: UIAction) -> Void in
            self.selectedIndex = Int(action.identifier.rawValue) ?? 0
        }

        if #available(macCatalyst 14.0, *) {
            let menu = UIMenu(children:
                items.enumerated().map { (index, item) in
                    UIAction(title: item.pickerDisplayName.string, identifier: .init(rawValue: String(index)), handler: action)
                }
            )
            button.menu = menu
            button.showsMenuAsPrimaryAction = true
        }

        // We don't need to show this button, we're just using it to accept hits and present the menu.
        button.isHidden = true
        return button
    }()
#else
    private(set) lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
#endif

    private(set) lazy var pickerFieldView: PickerFieldView = {
        let pickerFieldView = PickerFieldView(
            label: label,
            shouldShowChevron: disableDropdownWithSingleElement ? items.count != 1 : true,
            pickerView: pickerView,
            delegate: self,
            theme: theme,
            hasPadding: hasPadding,
            isOptional: isOptional
        )
        if disableDropdownWithSingleElement && items.count == 1 {
            pickerFieldView.isUserInteractionEnabled = false
        }
        return pickerFieldView
    }()

    // MARK: - Private properties
    private var previouslySelectedIndex: Int
    private let disableDropdownWithSingleElement: Bool
    private let isOptional: Bool

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
        hasPadding: Bool = true,
        disableDropdownWithSingleElement: Bool = false,
        isOptional: Bool = false,
        didUpdate: DidUpdateSelectedIndex? = nil
    ) {
        assert(!items.isEmpty, "`items` must contain at least one item")

        self.label = label
        self.theme = theme
        self.items = items
        self.disableDropdownWithSingleElement = disableDropdownWithSingleElement
        self.isOptional = isOptional
        self.didUpdate = didUpdate
        self.hasPadding = hasPadding

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

    public func select(index: Int, shouldAutoAdvance: Bool = true) {
        selectedIndex = index
        didFinish(pickerFieldView, shouldAutoAdvance: shouldAutoAdvance)
    }

    public func update(items: [DropdownItem]) {
        assert(!items.isEmpty, "`items` must contain at least one item")
        // Try to re-select the same item afer updating, if not possible default to the first item in the list
        let newSelectedIndex = items.firstIndex(where: { $0.rawData == self.items[selectedIndex].rawData }) ?? 0

        self.items = items
        self.select(index: newSelectedIndex, shouldAutoAdvance: false)
    }
}

private extension DropdownFieldElement {

    func updatePickerField() {
        #if targetEnvironment(macCatalyst)
        if #available(macCatalyst 14.0, *) {
            // Mark the enabled menu item as selected
            pickerView.menu?.children.forEach { ($0 as? UIAction)?.state = .off }
            (pickerView.menu?.children[selectedIndex] as? UIAction)?.state = .on
        }
        #else
        if pickerView.selectedRow(inComponent: 0) != selectedIndex {
            pickerView.reloadComponent(0)
            pickerView.selectRow(selectedIndex, inComponent: 0, animated: false)
        }
        #endif

        pickerFieldView.displayText = items[selectedIndex].labelDisplayName
        pickerFieldView.displayTextAccessibilityValue = items[selectedIndex].accessibilityValue
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

    public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let item = items[row]

        guard item.isPlaceholder else { return item.pickerDisplayName }

        // If this item is marked as a placeholder, apply placeholder text color
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: theme.colors.placeholderText]
        let placeholderString = NSAttributedString(string: item.pickerDisplayName.string, attributes: attributes)
        return placeholderString
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

    func didFinish(_ pickerFieldView: PickerFieldView, shouldAutoAdvance: Bool) {
        if previouslySelectedIndex != selectedIndex {
            didUpdate?(selectedIndex)
        }
        previouslySelectedIndex = selectedIndex

        if shouldAutoAdvance {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.continueToNextField(element: self)
            }
        }
    }

    func didCancel(_ pickerFieldView: PickerFieldView) {
        // Reset to previously selected index when canceling
        selectedIndex = previouslySelectedIndex
    }
}
