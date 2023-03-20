//
//  CGRect+StripeCameraCore.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 12/14/21.
//

import Foundation
import CoreGraphics

@_spi(STP) public extension CGRect {

    /// Represents the bounds of a normalized coordinate system with range from (0,0) to (1,1)
    static let normalizedBounds = CGRect(x: 0, y: 0, width: 1, height: 1)

    /**
     - Returns: A `CGRect` that has its y-coordinates inverted between the
     upper-left corner and lower-left corner.

     - Note:
     This should only be used for rects that are using a normalized
     coordinate system, meaning that the coordinate of the corner opposite
     origin is (1,1)
     */
    var invertedNormalizedCoordinates: CGRect {
        return CGRect(
            x: minX,
            y: 1 - minY - height,
            width: width,
            height: height
        )
    }

    /**
     Converts a rectangle that's using a normalized coordinate system from a
     center-crop coordinate system to an un-cropped coordinate system

     Example, if the original size has a portrait aspect ratio, center-cropping
     the rect will result in the square area:
     ```
     +---------+
     |         |
     |---------|
     |         |
     |         |
     |         |
     |---------|
     |         |
     +---------+
     ```

     This method converts the rect's coordinate relative to the center-cropped
     area into coordinates relative to the original un-cropped area:
     ```
                     +---------+
                     |         |
     +---------+     |         |
     |    +--+ |     |    +--+ |
     |    |  | | --> |    |  | |
     |    +--+ |     |    +--+ |
     +---------+     |         |
                     |         |
                     +---------+
     ```

     - Parameters:
       - size: The original size of the un-cropped area.
     */
    func convertFromNormalizedCenterCropSquare(
        toOriginalSize originalSize: CGSize
    ) -> CGRect {
        let croppedWidth = min(originalSize.width, originalSize.height)
        let scaleX = croppedWidth / originalSize.width
        let scaleY = croppedWidth / originalSize.height

        return CGRect(
            x: (minX - 0.5) * scaleX + 0.5,
            y: (minY - 0.5) * scaleY + 0.5,
            width: width * scaleX,
            height: height * scaleY
        )
    }
}
