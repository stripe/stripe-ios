//
//  SPMAnalyticsTests.swift
//

import UIKit
import XCTest

@testable import StripeCore

class StripeCoreAnalyticsTests: XCTestCase {
    func testInstallMethod() {
        XCTAssert(InstallMethod.current == .spm)
    }
}
