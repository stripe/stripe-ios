//
//  SoftLinkTests.swift
//  StripeConnectionsTests
//
//  Created by Vardges Avetisyan on 3/4/22.
//

import Foundation
@_spi(STP) import StripeCore
import XCTest

class SoftLinkTest: XCTestCase {
    func testLoadingImplementationClass() {
        let klass = NSClassFromString("StripeConnections.ConnectionsSDKImplementation") as? ConnectionsSDKInterface.Type
        XCTAssertNotNil(klass)
    }
}
