//
//  FaceCaptureScanningState.swift
//  StripeIdentity
//
//  Created by Stripe on 6/10/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

struct FaceCaptureScanningState: Equatable, ScanningState {
    enum Phase: Equatable {
        case front
        case left
        case right
    }

    var phase: Phase
    var frontSamples: [FaceScannerInputOutput]
    var leftSide: FaceScannerInputOutput?
    var rightSide: FaceScannerInputOutput?
    var supportsPoseCapture: Bool?

    static func initialValue() -> FaceCaptureScanningState {
        return .init()
    }

    init(
        phase: Phase = .front,
        frontSamples: [FaceScannerInputOutput] = [],
        leftSide: FaceScannerInputOutput? = nil,
        rightSide: FaceScannerInputOutput? = nil,
        supportsPoseCapture: Bool? = nil
    ) {
        self.phase = phase
        self.frontSamples = frontSamples
        self.leftSide = leftSide
        self.rightSide = rightSide
        self.supportsPoseCapture = supportsPoseCapture
    }

    var isComplete: Bool {
        return leftSide != nil && rightSide != nil
    }

    func captureData() -> FaceCaptureData? {
        return FaceCaptureData(
            samples: frontSamples,
            leftSide: leftSide,
            rightSide: rightSide
        )
    }
}
