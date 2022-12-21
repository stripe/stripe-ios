//
//  DetectedSSDOcrBox.swift
//  CardScan
//
//  Created by xaen on 3/22/20.
//
import CoreGraphics
import Foundation

struct DetectedSSDOcrBox {
    let rect: CGRect
    let label: Int
    let confidence: Float
    let imgSize: CGSize

    init(
        category: Int,
        conf: Float,
        XMin: Double,
        YMin: Double,
        XMax: Double,
        YMax: Double,
        imageSize: CGSize
    ) {

        let XMin_ = XMin * Double(imageSize.width)
        let XMax_ = XMax * Double(imageSize.width)
        let YMin_ = YMin * Double(imageSize.height)
        let YMax_ = YMax * Double(imageSize.height)

        self.label = category
        self.confidence = conf
        self.rect = CGRect(x: XMin_, y: YMin_, width: XMax_ - XMin_, height: YMax_ - YMin_)
        self.imgSize = imageSize
    }

    func toDict() -> [String: Any] {

        return ["": ""]
    }
}
