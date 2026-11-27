//
//  DropdownFieldElement.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
import UIKit

/**
 A textfield whose input view is a `UIPickerView` (on iOS) or a `UIMenu` (on Catalyst, or on iOS when `presentsAsMenu` is true) with a list of the strings.
 
 For internal SDK use only
 */
@_spi(InternalOnlyAPI) public final class DropdownFieldElement {
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
    public private(set) var isEditing: Bool = false {
        didSet {
            delegate?.didUpdate(element: self)
        }
    }
    public var didUpdate: DidUpdateSelectedIndex?
    public let theme: ElementsAppearance
    public let hasPadding: Bool

    /// A label displayed in the dropdown field UI e.g. "Country or region" for a country dropdown
    public let label: String?
#if targetEnvironment(macCatalyst) || canImport(visionOS)
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

    /// Presents `items` in a pop-up menu. Only used when `usesMenu` is true.
    private(set) lazy var menuButton: PickerFieldView.MenuButton = {
        var configuration = UIButton.Configuration.plain()
        // We don't need to show this button's title or indicator, we're just using it to accept hits and present the menu.
        configuration.baseForegroundColor = .clear
        if #available(iOS 16.0, *) {
            configuration.indicator = .none
        }
        let button = PickerFieldView.MenuButton(configuration: configuration)
        button.showsMenuAsPrimaryAction = true
        button.accessibilityLabel = label
        return button
    }()

    /// Whether `items` are presented in a `UIMenu` instead of a `UIPickerView`
    let usesMenu: Bool
#endif

    private(set) lazy var pickerFieldView: PickerFieldView = {
        #if targetEnvironment(macCatalyst) || canImport(visionOS)
        let pickerView: UIView = pickerView
        let presentsMenu = true
        #else
        let pickerView: UIView = usesMenu ? menuButton : pickerView
        let presentsMenu = usesMenu
        #endif
        let pickerFieldView = PickerFieldView(
            label: label,
            shouldShowChevron: disableDropdownWithSingleElement ? items.count != 1 : true,
            pickerView: pickerView,
            presentsMenu: presentsMenu,
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
    // Indicates if this dropdown should start with no selection. When true, a placeholder item is automatically
    // inserted at index 0 and selected by default so the user must actively make a choice.
    private let startsEmpty: Bool

    // MARK: Placeholder Helper
    /// Returns `items`, optionally prepending a fresh placeholder when `startsEmpty` is true.
    private func itemsWithOptionalPlaceholder(from items: [DropdownItem]) -> [DropdownItem] {
        guard startsEmpty else { return items }
        let placeholder = DropdownItem(
            pickerDisplayName: NSAttributedString(string: ""),
            labelDisplayName: NSAttributedString(string: ""),
            accessibilityValue: "",
            rawData: "",
            isPlaceholder: true,
            isDisabled: true
        )
        return [placeholder] + items
    }
    lazy var pickerViewDelegate: PickerViewDelegate = { PickerViewDelegate(self) }()

    /**
     - Parameters:
     - items: Items to populate this dropdown with.
     - defaultIndex: Defaults the dropdown to the item with the corresponding index.
     - label: Label for the dropdown
     - presentsAsMenu: Present `items` in a `UIMenu` instead of a `UIPickerView`. Items are shown using the plain string of their `pickerDisplayName`, and placeholder items are omitted.
     - didUpdate: Called when the user has finished selecting a new item.
     
     - Note:
     - Items must contain at least one item.
     - If `defaultIndex` is outside of the bounds of the `items` array, then a default of `0` is used.
     - `didUpdate` is not called if the user does not change their input before hitting "Done"
     */
    public init(
        items: [DropdownItem],
        defaultIndex: Int? = nil,
        label: String?,
        theme: ElementsAppearance = .default,
        hasPadding: Bool = true,
        disableDropdownWithSingleElement: Bool = false,
        isOptional: Bool = false,
        startsEmpty: Bool = false,
        presentsAsMenu: Bool = false,
        didUpdate: DidUpdateSelectedIndex? = nil
    ) {
        stpAssert(!items.filter { !$0.isDisabled }.isEmpty, "`items` must contain at least one non-disabled item; if this is a test, you might need to set AddressSpecProvider.shared.loadAddressSpecs")

        self.label = label
        self.theme = theme
        self.disableDropdownWithSingleElement = disableDropdownWithSingleElement
        self.isOptional = isOptional
        self.startsEmpty = startsEmpty
        self.didUpdate = didUpdate
        self.hasPadding = hasPadding
        #if !targetEnvironment(macCatalyst) && !canImport(visionOS)
        self.usesMenu = presentsAsMenu
        #endif

        let initialItems: [DropdownItem] = {
            guard startsEmpty else { return items }
            let placeholder = DropdownItem(
                pickerDisplayName: NSAttributedString(string: ""),
                labelDisplayName: NSAttributedString(string: ""),
                accessibilityValue: "",
                rawData: "",
                isPlaceholder: true,
                isDisabled: false
            )
            return [placeholder] + items
        }()
        self.items = initialItems

        // Determine initial selection
        let placeholders = initialItems.prefix { $0.isPlaceholder }.count
        let selectedIndex: Int = {
            if startsEmpty {
                guard let defaultIndex else { return 0 }
                let adjustedIndex = defaultIndex + placeholders
                return (0..<initialItems.count).contains(adjustedIndex) ? adjustedIndex : 0
            } else {
                let idx = defaultIndex ?? 0
                return (0..<initialItems.count).contains(idx) ? idx : 0
            }
        }()

        self.selectedIndex = selectedIndex
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
        let withPlaceholder = itemsWithOptionalPlaceholder(from: items)
        let newSelectedIndex = withPlaceholder.firstIndex(where: { $0.rawData == self.items[selectedIndex].rawData }) ?? (startsEmpty ? 0 : 0)

        self.items = withPlaceholder
        self.select(index: newSelectedIndex, shouldAutoAdvance: false)
    }
}

private extension DropdownFieldElement {

    func updatePickerField() {
        #if targetEnvironment(macCatalyst) || canImport(visionOS)
        if #available(macCatalyst 14.0, *) {
            // Mark the enabled menu item as selected
            pickerView.menu?.children.forEach { ($0 as? UIAction)?.state = .off }
            (pickerView.menu?.children[selectedIndex] as? UIAction)?.state = .on
        }
        #else
        if usesMenu {
            // Shows a checkmark next to the selected item and opens the menu scrolled to it.
            // Pop-up buttons always select an item, so only enable this once a non-placeholder item is selected.
            menuButton.changesSelectionAsPrimaryAction = !items[selectedIndex].isPlaceholder
            // Rebuild the menu so it reflects the current items and selection
            menuButton.menu = makeMenu()
            menuButton.accessibilityValue = items[selectedIndex].accessibilityValue
        } else if pickerView.selectedRow(inComponent: 0) != selectedIndex {
            // Update picker view selection directly using selectedIndex
            pickerView.reloadComponent(0)
            pickerView.selectRow(selectedIndex, inComponent: 0, animated: false)
        }
        #endif

        pickerFieldView.displayText = items[selectedIndex].labelDisplayName
        pickerFieldView.displayTextAccessibilityValue = items[selectedIndex].accessibilityValue

        // Ensure the floating placeholder view updates immediately so the label doesn't overlap.
        pickerFieldView.setNeedsLayout()
    }

    #if !targetEnvironment(macCatalyst) && !canImport(visionOS)
    func makeMenu() -> UIMenu {
        let actions: [UIAction] = items.enumerated().compactMap { index, item in
            guard !item.isPlaceholder else {
                return nil
            }
            let action = UIAction(title: item.pickerDisplayName.string) { [weak self] _ in
                self?.select(index: index, shouldAutoAdvance: false)
            }
            action.attributes = item.isDisabled ? .disabled : []
            action.state = index == selectedIndex ? .on : .off
            return action
        }
        return UIMenu(children: actions)
    }
    #endif
}

// MARK: Element

extension DropdownFieldElement: Element {
    public var collectsUserInput: Bool { true }

    struct EmptySelectionError: ElementValidationError {
        var localizedDescription: String = STPLocalizedString(
            "Selection is empty.",
            "Error message for empty dropdown selection."
        )
    }

    public var validationState: ElementValidationState {
        // If the field is optional, it's always valid even when empty.
        if isOptional {
            return .valid
        }

        // When the currently selected item is a placeholder, treat as invalid but don't display the error yet.
        if items[selectedIndex].isPlaceholder {
            return .invalid(error: EmptySelectionError(), shouldDisplay: false)
        }
        return .valid
    }

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
        isEditing = true
    }

    func didFinish(_ pickerFieldView: PickerFieldView, shouldAutoAdvance: Bool) {
        isEditing = false
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
