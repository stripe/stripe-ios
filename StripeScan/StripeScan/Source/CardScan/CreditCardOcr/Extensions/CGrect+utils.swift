//
//  CGrect+utils.swift
//  CardScan
//
//  Created by Jaime Park on 6/11/21.
//

import CoreGraphics

extension CGRect {
    func centerY() -> CGFloat {
        return (minY / 2 + maxY / 2)
    }

    func centerX() -> CGFloat {
        return (minX / 2 + maxX / 2)
    }
}
