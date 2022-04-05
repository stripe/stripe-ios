//
//  ConfirmButtonSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Nick Porter on 3/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
import FBSnapshotTestCase
import StripeCoreTestUtils

@testable @_spi(STP) import Stripe

class ConfirmButtonSnapshotTests: FBSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
//        self.recordMode = true
    }
    
    func testConfirmButton() {
        let confirmButton = ConfirmButton(style: .stripe, callToAction: .setup, didTap: {})
        
        verify(confirmButton)
    }
    
    func testConfirmButtonCustomFont() throws {
        var appearance = PaymentSheet.Appearance.default
        appearance.font.regular = try XCTUnwrap(UIFont(name: "AmericanTypewriter", size: 12.0))
        
        let confirmButton = ConfirmButton(style: .stripe,
                                          callToAction: .custom(title: "Custom Title"),
                                          appearance: appearance, didTap: {})
        
        verify(confirmButton)
    }
    
    func testConfirmButtonCustomFontScales() throws {
        var appearance = PaymentSheet.Appearance.default
        appearance.font.regular = try XCTUnwrap(UIFont(name: "AmericanTypewriter", size: 12.0))
        appearance.font.sizeScaleFactor = 0.85

        let confirmButton = ConfirmButton(style: .stripe,
                                          callToAction: .custom(title: "Custom Title"),
                                          appearance: appearance, didTap: {})
        
        verify(confirmButton)
    }
    
    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 300)
        FBSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}
