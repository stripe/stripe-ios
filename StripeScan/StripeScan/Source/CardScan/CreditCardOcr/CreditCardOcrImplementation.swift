//
//  CreditCardOcr.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/19/20.
//  Copyright © 2020 Sam King. All rights reserved.
//
import UIKit

/**
 Base class for any OCR prediction systems. All implementations must override `recognizeCard` and update the `frames`
 and `computationTime` member variables
 */

open class CreditCardOcrImplementation {
    let dispatchQueue: ActiveStateComputation
    public var frames = 0
    public var computationTime = 0.0
    let startTime = Date()
    
    var framesPerSecond: Double {
        return Double(frames) / -startTime.timeIntervalSinceNow
    }
    
    var mlFramesPerSecond: Double {
        return Double(frames) / computationTime
    }
    
    public init(dispatchQueueLabel: String) {
        self.dispatchQueue = ActiveStateComputation(label: dispatchQueueLabel)
    }
    
    public init(dispatchQueue: ActiveStateComputation) {
        self.dispatchQueue = dispatchQueue
    }
    
    open func recognizeCard(in fullImage: CGImage, roiRectangle: CGRect) -> CreditCardOcrPrediction {
        preconditionFailure("This method must be overridden")
    }
}
