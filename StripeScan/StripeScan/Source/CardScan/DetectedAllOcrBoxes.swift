//
//  DetectedAllOcrBoxes.swift
//  CardScan
//
//  Created by xaen on 3/22/20.
//
import CoreGraphics
import Foundation

public struct DetectedAllOcrBoxes {
    var allBoxes: [DetectedSSDOcrBox] = []
    
    public init() {}
    
    public func toArray() -> [[String: Any]]{
        let frameArray = self.allBoxes.map { $0.toDict() }
        return frameArray
    }
    
    public func getBoundingBoxesOfDigits() -> [CGRect] {
        return self.allBoxes.map { $0.rect }
    }
}
