//
//  ModelTests.swift
//  ModelTests
//

@_spi(STP) import StripeCardScan
import UIKit
import XCTest

class StripeCardScanAssetTests: XCTestCase {

    func testModelsLoad() {
        guard #available(iOS 11.2, *) else { return }
        XCTAssert(UxAnalyzer.loadModelFromBundle() != nil, "Ux model loaded")
        XCTAssert(SSDOcrDetect.loadModelFromBundle() != nil, "OCR model loaded")
    }

}
