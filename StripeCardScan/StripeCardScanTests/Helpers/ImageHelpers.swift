//
//  ImageHelpers.swift
//  StripeCardScanTests
//
//  Created by Sam King on 11/29/21.
//

import UIKit

struct ImageHelpers {
    static func getTestImageAndRoiRectangle() -> (UIImage, CGRect) {
        let bundle = Bundle(for: UxModelTests.self)
        let path = bundle.url(forResource: "synthetic_test_image", withExtension: "jpg")!
        let image = UIImage(contentsOfFile: path.path)!
        let cardWidth = CGFloat(977.0)
        let cardHeight = CGFloat(616.0)
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        
        let roiRectangle = CGRect(x: (imageWidth - cardWidth) * 0.5,
                                  y: (imageHeight - cardHeight) * 0.5,
                                  width: cardWidth,
                                  height: cardHeight)
        
        return (image, roiRectangle)
    }
}
