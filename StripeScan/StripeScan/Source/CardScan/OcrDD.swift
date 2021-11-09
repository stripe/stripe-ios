//
//  OcrDD.swift
//  CardScan
//
//  Created by xaen on 4/14/20.
//
import CoreGraphics
import Foundation
import UIKit

@available(iOS 11.2, *)
public class OcrDD{
    public var lastDetectedBoxes: [CGRect] = []
    var ssdOcr = SSDOcrDetect()
    public init() { }

    static func configure(){
        let ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()
    }

    public func perform(croppedCardImage: CGImage) -> String?{
        let number = ssdOcr.predict(image: UIImage(cgImage: croppedCardImage))
        self.lastDetectedBoxes = ssdOcr.lastDetectedBoxes
        return number
    }

}
