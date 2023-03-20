//
//  UIImage+StripeCoreTestingUtils.swift
//  StripeCoreTestUtils
//
//  Created by Ramon Torres on 11/9/21.
//

import UIKit

public extension UIImage {

    /// Returns a 24x24 icon for testing purposes.
    /// - Returns: Plus sign icon.
    class func mockIcon() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24))

        let icon = renderer.image { context in
            context.cgContext.move(to: CGPoint(x: 12, y: 4))
            context.cgContext.addLine(to: CGPoint(x: 12, y: 20))
            context.cgContext.move(to: CGPoint(x: 4, y: 12))
            context.cgContext.addLine(to: CGPoint(x: 20, y: 12))
            context.cgContext.setLineWidth(2)
            context.cgContext.setLineCap(.round)
            context.cgContext.strokePath()
        }

        return icon.withRenderingMode(.alwaysTemplate)
    }

}
