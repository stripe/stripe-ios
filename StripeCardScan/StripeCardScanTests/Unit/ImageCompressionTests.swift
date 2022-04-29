//
//  ImageCompressionTests.swift
//  StripeCardScanTests
//
//  Created by Sam King on 11/29/21.
//

@testable @_spi(STP) import StripeCardScan
import XCTest

class ImageCompressionTests: XCTestCase {

    var image: CGImage?
    var originalImageSize: CGSize?
    var roiRectangle: CGRect?
    
    override func setUpWithError() throws {
        let (image, roiRectangle) = ImageHelpers.getTestImageAndRoiRectangle()
        
        self.originalImageSize = image.size
        self.image = image.cgImage
        self.roiRectangle = roiRectangle
    }

    func testFullSize() throws {
        guard let image = image, let originalImageSize = originalImageSize, let roiRectangle = roiRectangle else {
            throw "invalid setup"
        }
        
        let scannedCard = ScannedCardImageData(previewLayerImage: image, previewLayerViewfinderRect: roiRectangle)
        let verificationFrame = scannedCard.toVerificationFramesData(imageConfig: nil)
        let imageData = verificationFrame.imageData
        let newImage = UIImage(data: imageData!)!
        XCTAssertEqual(newImage.size, originalImageSize)
        XCTAssertTrue(verificationFrame.viewfinderMargins.equal(to: roiRectangle))
    }
}

extension ViewFinderMargins {
    func equal(to rect: CGRect) -> Bool {
        let left = Int(rect.origin.x)
        let right = Int(rect.origin.x + rect.size.width)
        let upper = Int(rect.origin.y)
        let lower = Int(rect.origin.y + rect.size.height)
        
        return left == self.left && right == self.right && upper == self.upper && lower == self.lower
    }
}

extension CGRect {
    func scale(byX scaleX: CGFloat, byY scaleY: CGFloat) -> CGRect {
        return CGRect(x: self.origin.x * scaleX,
                      y: self.origin.y * scaleY,
                      width: self.size.width * scaleX,
                      height: self.size.height * scaleY)
    }
}

extension String: Error {}
