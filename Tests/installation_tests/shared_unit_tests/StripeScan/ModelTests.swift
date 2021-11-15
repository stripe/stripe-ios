//
//  ModelTests.swift
//  ModelTests
//

import UIKit
import XCTest

@testable import StripeScan

class StripeScanAssetTests: XCTestCase {

    func testModelsLoad() {
        guard #available(iOS 11.2, *) else { return }
        XCTAssert(UxAnalyzer.loadModelFromBundle() != nil, "Ux model loaded")
        XCTAssert(SSDOcrDetect.loadModelFromBundle() != nil, "OCR model loaded")
    }

}
