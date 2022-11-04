//
//  CreditCardOcr.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/19/20.
//  Copyright © 2020 Sam King. All rights reserved.
//
import UIKit

/// Base class for any OCR prediction systems. All implementations must override `recognizeCard` and update the `frames`
/// and `computationTime` member variables

@_spi(STP) public class CreditCardOcrImplementation {
    let dispatchQueue: ActiveStateComputation
    var frames = 0
    var computationTime = 0.0
    let startTime = Date()

    var framesPerSecond: Double {
        return Double(frames) / -startTime.timeIntervalSinceNow
    }

    var mlFramesPerSecond: Double {
        return Double(frames) / computationTime
    }

    init(
        dispatchQueueLabel: String
    ) {
        self.dispatchQueue = ActiveStateComputation(label: dispatchQueueLabel)
    }

    init(
        dispatchQueue: ActiveStateComputation
    ) {
        self.dispatchQueue = dispatchQueue
    }

    func recognizeCard(in fullImage: CGImage, roiRectangle: CGRect) -> CreditCardOcrPrediction {
        preconditionFailure("This method must be overridden")
    }
}
