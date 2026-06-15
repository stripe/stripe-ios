//
//  FaceCapturePose.swift
//  StripeIdentity
//
//  Created by Stripe on 6/10/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import CoreVideo
import Foundation

enum FaceCapturePose: String, Equatable {
    case front
    case left
    case right
}

struct FacePose: Equatable {
    enum Thresholds {
        static let pitchUpMin: Float = 10
        static let pitchDownMax: Float = -7
        static let yawRightMin: Float = 10
        static let yawLeftMax: Float = -10
    }

    let yaw: Float
    let pitch: Float
    let roll: Float

    var direction: FaceCapturePose {
        if yaw > Thresholds.yawRightMin {
            return .right
        } else if yaw < Thresholds.yawLeftMax {
            return .left
        } else {
            return .front
        }
    }
}

protocol FacePoseDetector {
    func detectPose(pixelBuffer: CVPixelBuffer) throws -> FacePose?
    func reset()
}

extension FacePoseDetector {
    func reset() {}
}
