//
//  DetectedAllOcrBoxes.swift
//  CardScan
//
//  Created by xaen on 3/22/20.
//
import CoreGraphics
import Foundation

struct DetectedAllOcrBoxes {
    var allBoxes: [DetectedSSDOcrBox] = []

    func getBoundingBoxesOfDigits() -> [CGRect] {
        return self.allBoxes.map { $0.rect }
    }
}
