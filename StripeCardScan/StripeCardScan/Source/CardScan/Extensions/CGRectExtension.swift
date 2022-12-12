//
//  CGRectExtension.swift
//  CardScan
//
//  Created by Zain on 8/17/19.
//
import CoreGraphics
import Foundation

extension CGRect {
    func iou(nextBox: CGRect) -> Float {
        let areaCurrent = self.width * self.height
        if areaCurrent <= 0 {
            return 0
        }

        let areaNext = nextBox.width * nextBox.height
        if areaNext <= 0 {
            return 0
        }

        let intersectionMinX = max(self.minX, nextBox.minX)
        let intersectionMinY = max(self.minY, nextBox.minY)
        let intersectionMaxX = min(self.maxX, nextBox.maxX)
        let intersectionMaxY = min(self.maxY, nextBox.maxY)
        let intersectionArea =
            max(intersectionMaxY - intersectionMinY, 0)
            * max(intersectionMaxX - intersectionMinX, 0)
        return Float(intersectionArea / (areaCurrent + areaNext - intersectionArea))
    }

}
