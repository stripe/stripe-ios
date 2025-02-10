//
//  SavedPaymentMethodRowButtonTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 2/10/25.
//

import Foundation
import XCTest
@testable import StripePaymentSheet

final class SavedPaymentMethodRowButtonTests: XCTestCase {
    
    private let mockPaymentMethod = STPPaymentMethod._testCard()
    private let appearance = PaymentSheet.Appearance()
    
    func testInitializationWithUnselectedState() {
        // Given (default init -> .unselected)
        let sut = SavedPaymentMethodRowButton(
            paymentMethod: mockPaymentMethod,
            appearance: appearance
        )
        
        XCTAssertEqual(sut.state, .unselected)
        XCTAssertFalse(sut.isSelected, "Button should be unselected by default")
        XCTAssertEqual(sut.previousSelectedState, .unselected, "previousSelectedState should be .unselected if not set")
        XCTAssertTrue(sut.chevronButton.isHidden, "Chevron should be hidden in unselected state")
        XCTAssertFalse(sut.rowButton.isSelected, "Row button should not be selected initially")
    }
    
    func testInitializationWithCustomStates() {
        // We provide a previousSelectedState and currentState
        let sut = SavedPaymentMethodRowButton(
            paymentMethod: mockPaymentMethod,
            appearance: appearance,
            showDefaultPMBadge: false,
            previousSelectedState: .selected,
            currentState: .editing(allowsRemoval: true, allowsUpdating: false)
        )
        
        XCTAssertEqual(sut.previousSelectedState, .selected, "previousSelectedState should match the value given at init")
        XCTAssertEqual(sut.state, .editing(allowsRemoval: true, allowsUpdating: false), "currentState should match the value given at init")
        XCTAssertFalse(sut.isSelected, "Button shouldn't be 'selected' when in .editing")
        XCTAssertFalse(sut.chevronButton.isHidden, "Chevron should be visible in editing mode")
    }
    
    func testSetStateEditing() {
        let sut = SavedPaymentMethodRowButton(
            paymentMethod: mockPaymentMethod,
            appearance: appearance
        )
        
        sut.state = .editing(allowsRemoval: true, allowsUpdating: false)
        
        XCTAssertEqual(sut.state, .editing(allowsRemoval: true, allowsUpdating: false))
        XCTAssertFalse(sut.isSelected, "isSelected should be false in editing state")
        XCTAssertFalse(sut.chevronButton.isHidden, "Chevron should be visible in editing mode")
    }
    
    func testStateTransitionUnselectedToSelected() {
        let sut = SavedPaymentMethodRowButton(
            paymentMethod: mockPaymentMethod,
            appearance: appearance,
            currentState: .unselected
        )
        
        sut.state = .selected
        
        XCTAssertTrue(sut.isSelected, "Button should become selected")
        XCTAssertEqual(sut.previousSelectedState, .unselected, "previousSelectedState should track the old value")
        XCTAssertTrue(sut.chevronButton.isHidden, "Chevron is hidden when not editing.")
    }
    
    func testSettingPreviousSelectedStateFromSelectedToEditing() {
        let sut = SavedPaymentMethodRowButton(
            paymentMethod: mockPaymentMethod,
            appearance: appearance,
            currentState: .selected
        )

        sut.state = .editing(allowsRemoval: true, allowsUpdating: true)
        
        XCTAssertEqual(sut.previousSelectedState, .selected, "previousSelectedState should capture the old value of .selected")
        XCTAssertFalse(sut.isSelected, "In editing state, the button is not selected")
        XCTAssertFalse(sut.rowButton.isSelected, "Row button should reflect isSelected == false in .editing")
        XCTAssertFalse(sut.chevronButton.isHidden, "Chevron should be visible in editing mode.")
    }
    
}
