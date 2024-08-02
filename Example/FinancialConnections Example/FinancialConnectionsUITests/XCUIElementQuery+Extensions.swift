//
//  XCUIElementQuery+Extensions.swift
//  FinancialConnectionsUITests
//
//  Created by Krisjanis Gaidis on 7/25/24.
//

import Foundation
import XCTest

extension XCUIElementQuery {

    var lastMatch: XCUIElement {
        guard count > 0 else {
            return firstMatch
        }
        return element(boundBy: count - 1)
    }
}
