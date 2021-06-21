//
//  SectionElementTest.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class SectionElementTest: XCTestCase {
    struct DummyTextFieldElementConfiguration: TextFieldElementConfiguration {
        let validationState: ElementValidationState
        let placeholder = "foo"
        func updateParams(for text: String, params: IntentConfirmParams) -> IntentConfirmParams? {
            return nil
        }
        func validate(text: String, isOptional: Bool) -> ElementValidationState {
            return validationState
        }
    }
    
    enum Error: TextFieldValidationError {
        case undisplayableError
        case displayableError
        
        var localizedDescription: String {
            switch self {
            case .undisplayableError:
                return "undisplayable error"
            case .displayableError:
                return "displayable error"
            }
        }
        
        func shouldDisplay(isUserEditing: Bool) -> Bool {
            switch self {
            case .undisplayableError:
                return false
            case .displayableError:
                return true
            }
        }
    }
    
    func testValidationStateAndError() {
        // Given an invalid element whose error shouldn't be displayed...
        let element1 = TextFieldElement(
            configuration: DummyTextFieldElementConfiguration(validationState: .invalid(Error.undisplayableError))
        )

        // ...and an invalid element whose error *should* be displayed...
        let element2 = TextFieldElement(
            configuration: DummyTextFieldElementConfiguration(validationState: .invalid(Error.displayableError))
        )
        
        // ...a section with these two elements....
        let section = SectionElement(title: "Foo", elements: [element1, element2])
        
        // ...should reflect the first invalid element as its `validationState`
        XCTAssertEqual(section.validationState, element1.validationState)
        
        // ...but display the first invalid element with a *displayable* error
        XCTAssertEqual(section.error, "displayable error")
    }
}

