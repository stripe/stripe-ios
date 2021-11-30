//
//  UxModelTests.swift
//  CardVerifyTests
//
//  Created by Sam King on 8/14/21.
//

@testable @_spi(STP) import StripeCardScan
import XCTest

class UxModelTests: XCTestCase {

    var image: CGImage?
    var roiRectangle: CGRect?
    
    override func setUpWithError() throws {
        let (image, roiRectangle) = ImageHelpers.getTestImageAndRoiRectangle()
        
        self.image = image.cgImage
        self.roiRectangle = roiRectangle
        
    }

    func testUxAndAppleAnalyzer() throws {
        guard let image = image, let roiRectangle = roiRectangle else { XCTAssert(false); return }
        guard #available(iOS 13.0, *) else { return }
        let ocr = AppleCreditCardOcr(dispatchQueueLabel: "test")
        let uxAnalyzer = UxAnalyzer(with: ocr)
        
        let prediction = uxAnalyzer.recognizeCard(in: image, roiRectangle: roiRectangle)
        XCTAssert(prediction.centeredCardState == .numberSide)
    }
    
    func testUxAndSsdAnalyzer() throws {
        guard let image = image, let roiRectangle = roiRectangle else { XCTAssert(false); return }
        guard #available(iOS 13.0, *) else { return }
        let ocr = SSDCreditCardOcr(dispatchQueueLabel: "test")
        let uxAnalyzer = UxAnalyzer(with: ocr)
        
        let prediction = uxAnalyzer.recognizeCard(in: image, roiRectangle: roiRectangle)
        XCTAssert(prediction.centeredCardState == .numberSide)
    }
}
