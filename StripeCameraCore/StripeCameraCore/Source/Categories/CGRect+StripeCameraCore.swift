//
//  CGRect+StripeCameraCore.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 12/14/21.
//

import Foundation
import CoreGraphics

@_spi(STP) public extension CGRect {
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
}
