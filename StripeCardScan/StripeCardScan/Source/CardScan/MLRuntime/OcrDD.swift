//
//  OcrDD.swift
//  CardScan
//
//  Created by xaen on 4/14/20.
//
import CoreGraphics
import Foundation
import UIKit

class OcrDD{
    var lastDetectedBoxes: [CGRect] = []
    var ssdOcr = SSDOcrDetect()
    init() { }

    static func configure(){
        let ssdOcr = SSDOcrDetect()
        ssdOcr.warmUp()
    }

    func perform(croppedCardImage: CGImage) -> String?{
        let number = ssdOcr.predict(image: UIImage(cgImage: croppedCardImage))
        self.lastDetectedBoxes = ssdOcr.lastDetectedBoxes
        return number
    }

}
