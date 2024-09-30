//
//  OnSetterFunctionCalledMessageHandlerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 9/23/24.
//

@testable import StripeConnect
import XCTest

class OnSetterFunctionCalledMessageHandlerTests: ScriptWebTestBase {
    func testDeallocation() {
        weak var weakInstance: OnSetterFunctionCalledMessageHandler?
        autoreleasepool {
            let instance = OnSetterFunctionCalledMessageHandler()
            weakInstance = instance
            XCTAssertNotNil(weakInstance)
        }
        XCTAssertNil(weakInstance)
    }
}
