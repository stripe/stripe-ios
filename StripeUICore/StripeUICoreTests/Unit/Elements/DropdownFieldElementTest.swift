//
//  DropdownFieldElementTest.swift
//  StripeUICoreTests
//
//  Created by Mel Ludowise on 10/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) @testable import StripeUICore
import UIKit
import XCTest

final class DropdownFieldElementTest: XCTestCase {

    let items = ["A", "B", "C", "D"].map { DropdownFieldElement.DropdownItem(pickerDisplayName: $0, labelDisplayName: $0, accessibilityValue: $0, rawData: $0) }

    func testNoDefault() {
        let element = DropdownFieldElement(items: items, label: "")
        XCTAssertEqual(element.selectedIndex, 0)
        XCTAssertNil(element.menuButton)
        let picker: UIPickerView = element.pickerView
        XCTAssertEqual(picker.numberOfComponents, 1)
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
        // Emulate a user changing the picker and hitting done button
        element.pickerView(element.pickerView, didSelectRow: 3, inComponent: 0)
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)
        XCTAssertEqual(index, 3)
    }

    func testDidUpdateToDefault() {
        // Ensure `didUpdate` is not called if the selection doesn't change

        var index: Int?
        let element = DropdownFieldElement(items: items, defaultIndex: 0, label: "", didUpdate: { index = $0 })
        XCTAssertNil(index)

        // Emulate a user changing the picker
        element.pickerView(element.pickerView, didSelectRow: 3, inComponent: 0)
        XCTAssertNil(index)

        // Emulate a user changing the picker back
        element.pickerView(element.pickerView, didSelectRow: 0, inComponent: 0)
        XCTAssertNil(index)

        // Emulate user hitting the done button
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)
        XCTAssertNil(index)
    }

    func testUpdate() {
        var index: Int?
        let element = DropdownFieldElement(items: items, label: "", didUpdate: { index = $0 })
        XCTAssertNil(index)
        // Emulate a user changing the picker and hitting done button
        element.pickerView(element.pickerView, didSelectRow: 3, inComponent: 0)
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)
        XCTAssertEqual(index, 3)

        // Update items with same list should keep original item selected
        element.update(items: items)
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)
        XCTAssertEqual(index, 3)

        // Update items removing/replacing item at index 4, should select the first index
        let items = ["A", "B", "C", "DD"].map { DropdownFieldElement.DropdownItem(pickerDisplayName: $0, labelDisplayName: $0, accessibilityValue: $0, rawData: $0) }
        element.update(items: items)
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)
        XCTAssertEqual(index, 0)
    }

    func testCantSelectDisabledItem() {
        let disabledItem = DropdownFieldElement.DropdownItem(pickerDisplayName: "Disabled",
                                                             labelDisplayName: "Disabled",
                                                             accessibilityValue: "Disabled",
                                                             rawData: "Disabled",
                                                             isDisabled: true)
        let itemsWithDisabled = items + [disabledItem]
        XCTAssertEqual(4, items.count)

        var index: Int?
        let element = DropdownFieldElement(items: itemsWithDisabled, defaultIndex: 0, label: "", didUpdate: { index = $0 })
        XCTAssertNil(index)

        // Emulate a user changing the picker and hitting the done button
        element.pickerView(element.pickerView, didSelectRow: 2, inComponent: 0)
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)
        XCTAssertEqual(index, 2)

        element.pickerView(element.pickerView, didSelectRow: 4, inComponent: 0)
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)
        // Should stay selected on previous selection
        XCTAssertEqual(index, 2)
    }

    // MARK: - Menu tests

    func testMenuCommitsOnceAndReselectDoesNotNotify() throws {
        var updates: [Int] = []
        let element = DropdownFieldElement(items: items, label: "Label", presentation: .menu, didUpdate: { updates.append($0) })
        let delegate = MenuDelegate()
        element.delegate = delegate
        let button = try XCTUnwrap(element.menuButton)
        let action = try XCTUnwrap(button.menu?.children[2] as? UIAction)

        // When the actual menu action is invoked
        button.sendAction(action)

        // Then the new selection is committed exactly once
        XCTAssertEqual(updates, [2])
        XCTAssertEqual(delegate.updates, 1)
        XCTAssertEqual(delegate.advances, 1)
        XCTAssertFalse(element.isEditing)
        XCTAssertEqual(element.selectedItem.rawData, "C")
        XCTAssertEqual(button.accessibilityLabel, "Label")
        XCTAssertEqual(button.accessibilityValue, "C")
        XCTAssertEqual((button.menu?.children[2] as? UIAction)?.state, .on)

        button.sendAction(try XCTUnwrap(button.menu?.children[2] as? UIAction))
        XCTAssertEqual(updates, [2])
        XCTAssertEqual(delegate.updates, 1)
    }

    func testMenuDisabledActionsAndFieldCannotCommit() throws {
        let disabledItem = DropdownFieldElement.DropdownItem(pickerDisplayName: "Disabled", labelDisplayName: "Disabled", accessibilityValue: "Disabled", rawData: "Disabled", isDisabled: true)
        let element = DropdownFieldElement(items: items + [disabledItem], label: "Label", presentation: .menu)
        let button = try XCTUnwrap(element.menuButton)
        let disabledAction = try XCTUnwrap(button.menu?.children.last as? UIAction)
        XCTAssertTrue(disabledAction.attributes.contains(.disabled))
        button.sendAction(disabledAction)
        XCTAssertEqual(element.selectedIndex, 0)

        // An action retained before an item becomes disabled must also be rejected.
        let staleAction = try XCTUnwrap(button.menu?.children[1] as? UIAction)
        let newlyDisabledItem = DropdownFieldElement.DropdownItem(pickerDisplayName: "B", labelDisplayName: "B", accessibilityValue: "B", rawData: "B", isDisabled: true)
        element.update(items: [items[0], newlyDisabledItem, items[2]])
        button.sendAction(staleAction)
        XCTAssertEqual(element.selectedIndex, 0)
        XCTAssertTrue((button.menu?.children[1] as? UIAction)?.attributes.contains(.disabled) == true)

        element.view.isUserInteractionEnabled = false
        XCTAssertFalse(button.isEnabled)
        XCTAssertFalse(element.beginEditing())
        button.sendAction(try XCTUnwrap(button.menu?.children[2] as? UIAction))
        XCTAssertEqual(element.selectedIndex, 0)
    }

    func testMenuPlaceholderKeepsOriginalIndices() throws {
        let element = DropdownFieldElement(items: items, label: "Label", startsEmpty: true, presentation: .menu)
        let button = try XCTUnwrap(element.menuButton)
        let actions = try XCTUnwrap(button.menu).children.compactMap { $0 as? UIAction }
        XCTAssertEqual(actions.map { $0.title }, ["A", "B", "C", "D"])
        XCTAssertEqual(actions.map { $0.identifier.rawValue }, ["1", "2", "3", "4"])
        XCTAssertTrue(actions.allSatisfy { $0.state == .off })
        XCTAssertFalse(element.validationState.isValid)

        button.sendAction(actions[0])
        XCTAssertEqual(element.selectedIndex, 1)
        XCTAssertEqual(element.selectedItem.rawData, "A")
        XCTAssertTrue(element.validationState.isValid)

        // Replacing the selected item restores empty validation without exposing the placeholder.
        element.select(index: 2, shouldAutoAdvance: false)
        element.update(items: [items[2]])

        XCTAssertEqual(element.selectedIndex, 0)
        XCTAssertFalse(element.validationState.isValid)
        let refreshedActions = try XCTUnwrap(button.menu).children.compactMap { $0 as? UIAction }
        XCTAssertEqual(refreshedActions.map { $0.title }, ["C"])
        XCTAssertEqual(refreshedActions.first?.identifier.rawValue, "1")
        XCTAssertEqual(refreshedActions.first?.state, .off)
        button.sendAction(try XCTUnwrap(refreshedActions.first))
        XCTAssertEqual(element.selectedIndex, 1)
        XCTAssertTrue(element.validationState.isValid)
    }

    func testMenuActionsDoNotRetainElement() throws {
        var element: DropdownFieldElement? = DropdownFieldElement(items: items, label: "Label", presentation: .menu)
        weak var weakElement = element
        let button = try XCTUnwrap(element?.menuButton)
        let action = try XCTUnwrap(button.menu?.children[1] as? UIAction)

        element = nil

        XCTAssertNil(weakElement)
        button.sendAction(action)
    }

    func testMenuUpdatesContentsAndProgrammaticCheckmarks() throws {
        var updates: [Int] = []
        let element = DropdownFieldElement(items: items, label: "Label", presentation: .menu, didUpdate: { updates.append($0) })
        let button = try XCTUnwrap(element.menuButton)
        let staleAction = try XCTUnwrap(button.menu?.children[0] as? UIAction)

        element.selectedIndex = 2
        XCTAssertEqual((button.menu?.children[0] as? UIAction)?.state, .off)
        XCTAssertEqual((button.menu?.children[2] as? UIAction)?.state, .on)
        button.sendAction(try XCTUnwrap(button.menu?.children[2] as? UIAction))
        XCTAssertTrue(updates.isEmpty)

        element.update(items: Array(items.reversed()))
        let actions = try XCTUnwrap(button.menu).children.compactMap { $0 as? UIAction }
        XCTAssertEqual(actions.map { $0.title }, ["D", "C", "B", "A"])
        XCTAssertEqual(element.selectedIndex, 1)
        XCTAssertEqual(actions[1].state, .on)
        button.sendAction(staleAction)
        XCTAssertEqual(element.selectedIndex, 1)
    }

    func testMenuProgrammaticFocusDoesNotShowKeyboardOrOpenMenu() throws {
        let element = DropdownFieldElement(items: items, label: "Label", presentation: .menu)
        let button = try XCTUnwrap(element.menuButton)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 600))
        let controller = UIViewController()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        controller.view.addSubview(element.view)
        element.view.frame = CGRect(x: 0, y: 0, width: 300, height: 60)

        XCTAssertTrue(element.beginEditing())
        XCTAssertTrue(button.isFirstResponder)
        XCTAssertFalse(element.isEditing)
        XCTAssertNil(button.inputView)
        XCTAssertNil(button.inputAccessoryView)
        XCTAssertTrue(element.pickerFieldView.resignFirstResponder())
        XCTAssertFalse(button.isFirstResponder)
    }

    func testMenuUsesOneAccessibleControlAndNoKeyboardInput() throws {
        let element = DropdownFieldElement(items: items, label: "Label", presentation: .menu)
        let button = try XCTUnwrap(element.menuButton)
        let field = element.pickerFieldView
        XCTAssertEqual(field.accessibilityElements?.count, 1)
        XCTAssertTrue(field.accessibilityElements?.first as? UIButton === button)
        field.frame = CGRect(x: 0, y: 0, width: 300, height: 60)
        field.layoutIfNeeded()
        XCTAssertTrue(field.hitTest(CGPoint(x: 20, y: 20), with: nil) === button)
        let stack = try XCTUnwrap(field.subviews.first as? UIStackView)
        let placeholder = try XCTUnwrap(stack.arrangedSubviews.first)
        let textField = try XCTUnwrap(placeholder.subviews.compactMap { $0 as? UITextField }.first)
        XCTAssertNil(textField.inputView)
        XCTAssertNil(textField.inputAccessoryView)
        XCTAssertFalse(field.textFieldShouldBeginEditing(textField))
        field.setCanBecomeFirstResponder(false)
        XCTAssertFalse(field.becomeFirstResponder())
    }

    private class MenuDelegate: ElementDelegate {
        var updates = 0
        var advances = 0
        func didUpdate(element: Element) { updates += 1 }
        func continueToNextField(element: Element) { advances += 1 }
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

        // Select row 2
        element.pickerView(element.pickerView, didSelectRow: 2, inComponent: 0)
        element.didFinish(element.pickerFieldView, shouldAutoAdvance: true)

        XCTAssertEqual(didUpdateIndex, 2)
        XCTAssertTrue(element.validationState.isValid)
    }

}
