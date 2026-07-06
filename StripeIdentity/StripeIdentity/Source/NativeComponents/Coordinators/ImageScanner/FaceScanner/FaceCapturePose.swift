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
        static let yawRightMin: Float = 15
        static let yawLeftMax: Float = -15
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

struct FaceGeometry: Equatable {
    let faceDetectorOutput: FaceDetectorOutput
    let facePose: FacePose?
    let faceLandmarkResult: String?

    init(
        faceDetectorOutput: FaceDetectorOutput,
        facePose: FacePose?,
        faceLandmarkResult: String? = nil
    ) {
        self.faceDetectorOutput = faceDetectorOutput
        self.facePose = facePose
        self.faceLandmarkResult = faceLandmarkResult
    }
}

protocol FaceGeometryDetector {
    func detectFace(pixelBuffer: CVPixelBuffer) throws -> FaceGeometry?
    func reset()
}

extension FaceGeometryDetector {
    func reset() {}
}
