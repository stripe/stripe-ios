//
//  TwoOptionSelectorElementTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/20/26.

@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripeUICore
import UIKit
import XCTest

@MainActor
final class TwoOptionSelectorElementTests: XCTestCase {

    // MARK: - Initialization

    func testInitialSelectionAndIdentifiers() {
        let element = makeElement(left: ("a", "Alpha", "option_a"), right: ("b", "Beta", "option_b"), selectedId: "a")

        XCTAssertEqual(element.selectedItemId, "a")
        XCTAssertEqual(buttonIdentifiers(in: element.view), ["option_a", "option_b"])
        XCTAssertTrue(element.collectsUserInput)
        XCTAssertTrue(element.validationState.isValid)
    }

    // MARK: - User tap

    func testTapSelectsNewItemAndNotifiesDelegate() throws {
        let delegate = MockTwoOptionDelegate()
        let element = makeElement(left: ("a", "A", "option_a"), right: ("b", "B", "option_b"), selectedId: "a")
        element.delegate = delegate

        let bButton = try XCTUnwrap(button(in: element.view, id: "option_b"))
        bButton.sendActions(for: .touchUpInside)

        XCTAssertEqual(element.selectedItemId, "b")
        XCTAssertTrue(delegate.didUpdateCalled)
    }

    func testTapOnAlreadySelectedItemIsNoOp() throws {
        let delegate = MockTwoOptionDelegate()
        let element = makeElement(left: ("a", "A", "option_a"), right: ("b", "B", "option_b"), selectedId: "a")
        element.delegate = delegate

        let aButton = try XCTUnwrap(button(in: element.view, id: "option_a"))
        aButton.sendActions(for: .touchUpInside)

        XCTAssertEqual(element.selectedItemId, "a")
        XCTAssertFalse(delegate.didUpdateCalled)
    }

    // MARK: - Programmatic selection

    func testProgrammaticSelectNotifiesDelegate() {
        let delegate = MockTwoOptionDelegate()
        let element = makeElement(left: ("a", "A", "option_a"), right: ("b", "B", "option_b"), selectedId: "a")
        element.delegate = delegate

        element.select("b")

        XCTAssertEqual(element.selectedItemId, "b")
        XCTAssertTrue(delegate.didUpdateCalled)
    }

    func testProgrammaticSelectWithInvalidIdIsNoOp() {
        let delegate = MockTwoOptionDelegate()
        let element = makeElement(left: ("a", "A", "option_a"), right: ("b", "B", "option_b"), selectedId: "a")
        element.delegate = delegate

        element.select("nonexistent")

        XCTAssertEqual(element.selectedItemId, "a")
        XCTAssertFalse(delegate.didUpdateCalled)
    }

    // MARK: - Caption

    func testCaptionShownWhenProvided() {
        let element = makeElement(left: ("a", "A", "option_a"), right: ("b", "B", "option_b"), selectedId: "a", caption: "Some info")

        let label = captionLabel(in: element.view)
        XCTAssertEqual(label?.text, "Some info")
        XCTAssertEqual(label?.isHidden, false)
    }

    func testCaptionHiddenWhenNil() {
        let element = makeElement(left: ("a", "A", "option_a"), right: ("b", "B", "option_b"), selectedId: "a", caption: nil)

        let label = captionLabel(in: element.view)
        XCTAssertEqual(label?.isHidden, true)
    }

    // MARK: - Enabled / Disabled

    func testSetEnabledTogglesButtonsAndAlpha() {
        let element = makeElement(left: ("a", "A", "option_a"), right: ("b", "B", "option_b"), selectedId: "a")

        element.setEnabled(false)
        XCTAssertTrue(allButtons(in: element.view).allSatisfy { !$0.isEnabled })
        XCTAssertEqual(element.view.alpha, 0.6, accuracy: 0.001)

        element.setEnabled(true)
        XCTAssertTrue(allButtons(in: element.view).allSatisfy(\.isEnabled))
        XCTAssertEqual(element.view.alpha, 1.0, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func makeElement(
        left: (String, String, String),
        right: (String, String, String),
        selectedId: String,
        caption: String? = nil
    ) -> TwoOptionSelectorElement {
        TwoOptionSelectorElement(
            leftItem: TwoOptionSelectorItem(id: left.0, displayText: left.1, accessibilityIdentifier: left.2),
            rightItem: TwoOptionSelectorItem(id: right.0, displayText: right.1, accessibilityIdentifier: right.2),
            selectedItemId: selectedId,
            caption: caption,
            appearance: .default
        )
    }

    private func buttonIdentifiers(in view: UIView) -> [String] {
        allButtons(in: view).compactMap(\.accessibilityIdentifier)
    }

    private func button(in view: UIView, id: String) -> UIButton? {
        allButtons(in: view).first(where: { $0.accessibilityIdentifier == id })
    }

    private func captionLabel(in view: UIView) -> UILabel? {
        allSubviews(in: view).compactMap({ $0 as? UILabel }).first(where: { $0.numberOfLines == 0 })
    }

    private func allButtons(in view: UIView) -> [UIButton] {
        allSubviews(in: view).compactMap { $0 as? UIButton }
    }

    private func allSubviews(in view: UIView) -> [UIView] {
        view.subviews + view.subviews.flatMap(allSubviews(in:))
    }
}

private final class MockTwoOptionDelegate: ElementDelegate {
    var didUpdateCalled = false

    func didUpdate(element: Element) {
        didUpdateCalled = true
    }

    func continueToNextField(element: Element) {}
}
