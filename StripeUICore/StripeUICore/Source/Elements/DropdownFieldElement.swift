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
@_spi(STP) public final class DropdownFieldElement {
    public typealias DidUpdateSelectedIndex = (Int) -> Void

    public struct DropdownItem {
        public init(pickerDisplayName: NSAttributedString, labelDisplayName: NSAttributedString, accessibilityValue: String, rawData: String, isPlaceholder: Bool = false, isDisabled: Bool = false) {
            self.pickerDisplayName = pickerDisplayName
            self.labelDisplayName = labelDisplayName
            self.accessibilityValue = accessibilityValue
            self.isPlaceholder = isPlaceholder
            self.rawData = rawData
            self.isDisabled = isDisabled
        }

        public init(pickerDisplayName: String, labelDisplayName: String, accessibilityValue: String, rawData: String, isPlaceholder: Bool = false, isDisabled: Bool = false) {
            self = .init(pickerDisplayName: NSAttributedString(string: pickerDisplayName),
                         labelDisplayName: NSAttributedString(string: labelDisplayName),
                         accessibilityValue: accessibilityValue,
                         rawData: rawData,
                         isPlaceholder: isPlaceholder,
                         isDisabled: isDisabled)
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

        public let isDisabled: Bool
    }

    // MARK: - Public properties
    weak public var delegate: ElementDelegate?
    public private(set) var items: [DropdownItem]
    public var nonPlacerholderItems: [DropdownItem] {
        return items.filter({ !$0.isPlaceholder })
    }
    public var selectedItem: DropdownItem {
        return items[selectedIndex]
    }
    public var selectedIndex: Int {
        didSet {
            updatePickerField()
        }
    }
    public var didUpdate: DidUpdateSelectedIndex?
    public let theme: ElementsAppearance
    public let hasPadding: Bool

    /// A label displayed in the dropdown field UI e.g. "Country or region" for a country dropdown
    public let label: String?
#if targetEnvironment(macCatalyst) || canImport(CompositorServices)
    private(set) lazy var pickerView: UIButton = {
        let button = UIButton()
        let action = { (action: UIAction) in
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
        picker.delegate = pickerViewDelegate
        picker.dataSource = pickerViewDelegate
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
    lazy var pickerViewDelegate: PickerViewDelegate = { PickerViewDelegate(self) }()

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
        theme: ElementsAppearance = .default,
        hasPadding: Bool = true,
        disableDropdownWithSingleElement: Bool = false,
        isOptional: Bool = false,
        didUpdate: DidUpdateSelectedIndex? = nil
    ) {
        stpAssert(!items.filter { !$0.isDisabled }.isEmpty, "`items` must contain at least one non-disabled item; if this is a test, you might need to set AddressSpecProvider.shared.loadAddressSpecs")

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
        // Try to re-select the same item after updating, if not possible default to the first item in the list
        let newSelectedIndex = items.firstIndex(where: { $0.rawData == self.items[selectedIndex].rawData }) ?? 0

        self.items = items
        self.select(index: newSelectedIndex, shouldAutoAdvance: false)
    }
}

private extension DropdownFieldElement {

    func updatePickerField() {
        #if targetEnvironment(macCatalyst) || canImport(CompositorServices)
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
    public var collectsUserInput: Bool { true }

    public var view: UIView {
        return pickerFieldView
    }

    public func beginEditing() -> Bool {
        return pickerFieldView.becomeFirstResponder()
    }
}

// MARK: UIPickerViewDelegate & UIPickerViewDataSource

extension DropdownFieldElement {
    // A silly bridge class to work around the fact that UIPickerViewDelegate must be an NSObject
    class PickerViewDelegate: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
        weak var dropdownFieldElement: DropdownFieldElement?
        init(_ dropdownFieldElement: DropdownFieldElement?) {
            self.dropdownFieldElement = dropdownFieldElement
        }

        public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
            guard let dropdownFieldElement else { return nil }
            let item = dropdownFieldElement.items[row]

            guard item.isPlaceholder || item.isDisabled else { return item.pickerDisplayName }

            // If this item is marked as a placeholder or disabled, apply placeholder text color
            let placeholderString = NSMutableAttributedString(attributedString: item.pickerDisplayName)
            let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: dropdownFieldElement.theme.colors.placeholderText]
            placeholderString.addAttributes(attributes, range: NSRange(location: 0, length: placeholderString.length))

            return placeholderString
        }

        public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            dropdownFieldElement?.pickerView(pickerView, didSelectRow: row, inComponent: component)
        }

        public func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }

        public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return dropdownFieldElement?.items.count ?? 0
        }
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard row < items.count else {
            stpAssertionFailure("DropdownFieldElement selected row (\(row)) is out of bounds. Total dropdown items: \(items.count)")
            return
        }
        let item = items[row]
        // If a user selects a disable row, reset to the previous selection
        if item.isDisabled {
            pickerView.selectRow(selectedIndex, inComponent: 0, animated: true)
            return
        }

        selectedIndex = row
    }
}

// MARK: - PickerFieldViewDelegate

extension DropdownFieldElement: PickerFieldViewDelegate {
    func didBeginEditing(_ pickerFieldView: PickerFieldView) {
    }

    func didFinish(_ pickerFieldView: PickerFieldView, shouldAutoAdvance: Bool) {
        if previouslySelectedIndex != selectedIndex {
            didUpdate?(selectedIndex)
        }
        previouslySelectedIndex = selectedIndex

        if shouldAutoAdvance {
            delegate?.didUpdate(element: self)
            delegate?.continueToNextField(element: self)
            // If the picker field view is still selected (e.g. if someone tapped "Done"), dismiss it on the next runloop
            DispatchQueue.main.async {
                _ = pickerFieldView.resignFirstResponder()
            }
        }
    }

    func didCancel(_ pickerFieldView: PickerFieldView) {
        // Reset to previously selected index when canceling
        selectedIndex = previouslySelectedIndex
    }
}

// MARK: - DebugDescription
extension DropdownFieldElement {
    public var debugDescription: String {
        return "<DropdownFieldElement: \(Unmanaged.passUnretained(self).toOpaque())>; label = \(label ?? "nil"); validationState = \(validationState); rawData = \(rawData)"
    }
}
