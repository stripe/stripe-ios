//
//  XCTestCase+Extensions.swift
//  FinancialConnectionsUITests
//
//  Created by Krisjanis Gaidis on 2/22/24.
//

import Foundation
import XCTest

extension XCTestCase {

    func clear(textField: XCUIElement) {
        wait(timeout: 1.5) // wait for keyboard to appear, otherwise `textField.coordinate` may select the wrong spot
        while
            let text = textField.value as? String,
            !text.isEmpty,
            text != textField.placeholderValue
        {
            let middleCoordinate = textField.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.50))
            middleCoordinate.tap()
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: text.count)
            textField.typeText(deleteString)
        }
    }
}
