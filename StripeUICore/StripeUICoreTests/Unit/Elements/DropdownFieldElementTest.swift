//
//  DropdownFieldElementTest.swift
//  StripeUICoreTests
//
//  Created by Mel Ludowise on 10/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) @testable import StripeUICore
import XCTest

final class DropdownFieldElementTest: XCTestCase {

    let items = ["A", "B", "C", "D"].map { DropdownFieldElement.DropdownItem(pickerDisplayName: $0, labelDisplayName: $0, accessibilityValue: $0, rawData: $0) }

    func testNoDefault() {
        let element = DropdownFieldElement(items: items, label: "")
        XCTAssertEqual(element.selectedIndex, 0)
    }

    func testWithDefault() {
        let element = DropdownFieldElement(items: items, defaultIndex: 3, label: "")
        XCTAssertEqual(element.selectedIndex, 3)
    }

    func testDefaultExceedsMax() {
        let element = DropdownFieldElement(items: items, defaultIndex: items.count, label: "")
        XCTAssertEqual(element.selectedIndex, 0)
    }

    func testDefaultExceedsMin() {
        let element = DropdownFieldElement(items: items, defaultIndex: -1, label: "")
        XCTAssertEqual(element.selectedIndex, 0)
    }

    func testDisableDropdownWithSingleElement() {
        let multipleElements = DropdownFieldElement(items: items, defaultIndex: -1, label: "", disableDropdownWithSingleElement: true)

        XCTAssertEqual(multipleElements.pickerFieldView.isUserInteractionEnabled, true)

        let singleElement = DropdownFieldElement(items: [DropdownFieldElement.DropdownItem(pickerDisplayName: "Item", labelDisplayName: "Item", accessibilityValue: "Item", rawData: "Item")], defaultIndex: -1, label: "", disableDropdownWithSingleElement: true)

        XCTAssertEqual(singleElement.pickerFieldView.isUserInteractionEnabled, false)
    }

    func testDidUpdate() {
        var index: Int?
        let element = DropdownFieldElement(items: items, label: "", didUpdate: { index = $0 })
        XCTAssertNil(index)
        // Emulate a user selecting an item from the menu
        element.selectMenuItem("D")
        XCTAssertEqual(index, 3)
    }

    func testDidUpdateToDefault() {
        // Ensure `didUpdate` is not called if the selection doesn't change

        var index: Int?
        let element = DropdownFieldElement(items: items, defaultIndex: 0, label: "", didUpdate: { index = $0 })
        XCTAssertNil(index)

        // Emulate a user selecting the already selected item from the menu
        element.selectMenuItem("A")
        XCTAssertNil(index)
    }

    func testUpdate() {
        var index: Int?
        let element = DropdownFieldElement(items: items, label: "", didUpdate: { index = $0 })
        XCTAssertNil(index)
        // Emulate a user selecting an item from the menu
        element.selectMenuItem("D")
        XCTAssertEqual(index, 3)

        // Update items with same list should keep original item selected
        element.update(items: items)
        XCTAssertEqual(element.selectedIndex, 3)

        // Update items removing/replacing item at index 4, should select the first index
        let items = ["A", "B", "C", "DD"].map { DropdownFieldElement.DropdownItem(pickerDisplayName: $0, labelDisplayName: $0, accessibilityValue: $0, rawData: $0) }
        element.update(items: items)
        XCTAssertEqual(index, 0)
    }

    func testDisabledItemIsDisabledInMenu() {
        let disabledItem = DropdownFieldElement.DropdownItem(pickerDisplayName: "Disabled",
                                                             labelDisplayName: "Disabled",
                                                             accessibilityValue: "Disabled",
                                                             rawData: "Disabled",
                                                             isDisabled: true)
        let element = DropdownFieldElement(items: items + [disabledItem], defaultIndex: 0, label: "")

        // The menu prevents users from selecting the disabled item
        XCTAssertEqual(element.menuActions.map { $0.attributes.contains(.disabled) }, [false, false, false, false, true])
    }

    // MARK: - startsEmpty tests

    func testStartsEmptyInitialState() {
        let element = DropdownFieldElement(items: items, label: "", startsEmpty: true)
        // First item should be the auto-generated placeholder
        XCTAssertTrue(element.items.first?.isPlaceholder ?? false)
        // Placeholder selected
        XCTAssertEqual(element.selectedIndex, 0)
        // Validation should be invalid (not empty optional)
        XCTAssertFalse(element.validationState.isValid)
    }

    func testStartsEmptyOptionalIsValid() {
        let element = DropdownFieldElement(items: items, label: "", isOptional: true, startsEmpty: true)
        XCTAssertTrue(element.items.first?.isPlaceholder ?? false)
        XCTAssertEqual(element.selectedIndex, 0)
        // Optional field with no selection should still be valid
        XCTAssertTrue(element.validationState.isValid)
    }

    func testStartsEmptySelectingItemUpdatesValidation() {
        var didUpdateIndex: Int?
        let element = DropdownFieldElement(items: items, label: "", startsEmpty: true, didUpdate: { didUpdateIndex = $0 })

        // Select the second item; the placeholder is at index 0
        element.selectMenuItem("B")

        XCTAssertEqual(didUpdateIndex, 2)
        XCTAssertTrue(element.validationState.isValid)
    }

    // MARK: - Menu

    func testMenuReflectsItemsAndSelection() {
        // Given a dropdown presented as a menu with a disabled item
        var items = self.items
        items.append(.init(pickerDisplayName: "E", labelDisplayName: "E", accessibilityValue: "E", rawData: "E", isDisabled: true))
        let element = DropdownFieldElement(items: items, defaultIndex: 2, label: "Letter")

        // Then the menu button is overlaid on the field and has a menu item for each item, with the default selected
        XCTAssertTrue(element.menuButton.isDescendant(of: element.pickerFieldView))
        let actions = element.menuActions
        XCTAssertEqual(actions.map(\.title), ["A", "B", "C", "D", "E"])
        XCTAssertEqual(actions.map(\.state), [.off, .off, .on, .off, .off])
        XCTAssertEqual(actions.map { $0.attributes.contains(.disabled) }, [false, false, false, false, true])
        // ...and the menu button is the accessibility element
        XCTAssertEqual(element.menuButton.accessibilityLabel, "Letter")
        XCTAssertEqual(element.menuButton.accessibilityValue, "C")
    }

    func testMenuUpdatesWhenSelectionChanges() {
        // Given a dropdown presented as a menu
        var index: Int?
        let element = DropdownFieldElement(items: items, label: "", didUpdate: { index = $0 })

        // When a new item is selected
        element.select(index: 3, shouldAutoAdvance: false)

        // Then the menu marks the new item as selected
        let actions = element.menuActions
        XCTAssertEqual(actions.map(\.state), [.off, .off, .off, .on])
        XCTAssertEqual(element.menuButton.accessibilityValue, "D")
        // ...and didUpdate is called
        XCTAssertEqual(index, 3)
    }

    func testMenuUpdatesWhenItemsChange() {
        // Given a dropdown presented as a menu with "B" selected
        let element = DropdownFieldElement(items: items, defaultIndex: 1, label: "")

        // When the items are updated
        let newItems = ["B", "X"].map { DropdownFieldElement.DropdownItem(pickerDisplayName: $0, labelDisplayName: $0, accessibilityValue: $0, rawData: $0) }
        element.update(items: newItems)

        // Then the menu shows the new items with "B" still selected
        let actions = element.menuActions
        XCTAssertEqual(actions.map(\.title), ["B", "X"])
        XCTAssertEqual(actions.map(\.state), [.on, .off])
    }

    func testMenuOmitsPlaceholder() {
        // Given a dropdown presented as a menu that starts empty
        let element = DropdownFieldElement(items: items, label: "", startsEmpty: true)

        // Then the placeholder isn't shown in the menu
        let actions = element.menuActions
        XCTAssertEqual(actions.map(\.title), ["A", "B", "C", "D"])
        XCTAssertTrue(actions.allSatisfy { $0.state == .off })
    }

    func testMenuFocusDoesNotOpenMenu() {
        // Given a dropdown presented as a menu, shown after a text field that's being edited
        let element = DropdownFieldElement(items: items, label: "")
        let textField = UITextField()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 600))
        window.addSubview(textField)
        window.addSubview(element.view)
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        XCTAssertTrue(textField.becomeFirstResponder())

        // When focus moves to the dropdown
        XCTAssertTrue(element.beginEditing())

        // Then the menu button is focused and the text field stops editing
        XCTAssertTrue(element.menuButton.isFirstResponder)
        XCTAssertFalse(textField.isFirstResponder)

        // When the dropdown resigns
        XCTAssertTrue(element.pickerFieldView.resignFirstResponder())

        // Then the menu button is no longer focused
        XCTAssertFalse(element.menuButton.isFirstResponder)
    }

    func testMenuButtonDisabledWithField() {
        // Given a dropdown presented as a menu
        let element = DropdownFieldElement(items: items, label: "")
        XCTAssertTrue(element.menuButton.isEnabled)

        // When the field is disabled
        element.pickerFieldView.isUserInteractionEnabled = false

        // Then the menu button is disabled and can't be focused
        XCTAssertFalse(element.menuButton.isEnabled)
        XCTAssertFalse(element.beginEditing())

        // When the field is enabled again
        element.pickerFieldView.isUserInteractionEnabled = true

        // Then the menu button is enabled
        XCTAssertTrue(element.menuButton.isEnabled)
    }

    func testMenuButtonDisabledWithSingleElement() {
        // Given a dropdown presented as a menu that's disabled because it has a single item
        let element = DropdownFieldElement(items: [items[0]], label: "", disableDropdownWithSingleElement: true)

        // Then the menu button is disabled
        XCTAssertFalse(element.menuButton.isEnabled)
    }

    func testStateDropdownPresentsAsMenuWithPlaceholder() throws {
        // Given a state dropdown with no default
        let spec = AddressSpec(stateNameType: .state, subKeys: ["CA", "NY"], subLabels: ["California", "New York"])
        let element = try XCTUnwrap(spec.makeStateElement(defaultValue: nil, stateDict: ["CA": "California", "NY": "New York"]) as? DropdownFieldElement)

        // Then its menu doesn't include the placeholder or a selected item
        XCTAssertTrue(element.selectedItem.isPlaceholder)
        XCTAssertFalse(element.validationState.isValid)
        var actions = element.menuActions
        XCTAssertEqual(actions.map(\.title), ["California", "New York"])
        XCTAssertEqual(actions.map(\.state), [.off, .off])
        // ...and the menu button doesn't show a selection
        XCTAssertFalse(element.menuButton.changesSelectionAsPrimaryAction)
        XCTAssertEqual(element.menuButton.accessibilityValue, "")

        // When a state is selected from the menu
        var index: Int?
        element.didUpdate = { index = $0 }
        element.menuButton.sendAction(actions[1])

        // Then the state is selected
        XCTAssertEqual(index, 2)
        XCTAssertEqual(element.selectedItem.rawData, "NY")
        XCTAssertTrue(element.validationState.isValid)
        // ...and the menu button shows the selection
        actions = element.menuActions
        XCTAssertEqual(actions.map(\.state), [.off, .on])
        XCTAssertTrue(element.menuButton.changesSelectionAsPrimaryAction)
        XCTAssertEqual(element.menuButton.accessibilityValue, "New York")
    }

}

private extension DropdownFieldElement {
    var menuActions: [UIAction] {
        return menuButton.menu?.children.compactMap { $0 as? UIAction } ?? []
    }

    /// Emulates a user selecting the item titled `title` from the menu
    func selectMenuItem(_ title: String, file: StaticString = #filePath, line: UInt = #line) {
        guard let action = menuActions.first(where: { $0.title == title }) else {
            XCTFail("No menu item titled \(title)", file: file, line: line)
            return
        }
        menuButton.sendAction(action)
    }
}
