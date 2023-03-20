//
//  FaceCaptureData.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/4/22.
//

import Foundation
import CoreGraphics
@_spi(STP) import StripeCameraCore

struct FaceScannerInputOutput: Equatable {
    let image: CGImage
    let scannerOutput: FaceScannerOutput
    let cameraExifMetadata: CameraExifMetadata?
}

struct FaceCaptureData: Equatable {
    let first: FaceScannerInputOutput
    let last: FaceScannerInputOutput
    let bestMiddle: FaceScannerInputOutput

    let numSamples: Int
    let faceScoreVariance: Float

    var toArray: [FaceScannerInputOutput] {
        return [first, bestMiddle, last]
    }
}

extension FaceCaptureData {
    init?(samples: [FaceScannerInputOutput]) {
        guard let first = samples.first,
              let last = samples.last,
              samples.count >= 3,
              let bestMiddle = samples[1..<samples.count-1].max(by: { $0.scannerOutput.quality < $1.scannerOutput.quality })
        else {
            return nil
        }
        self.init(
            first: first,
            last: last,
            bestMiddle: bestMiddle,
            numSamples: samples.count,
            faceScoreVariance: samples.standardDeviation(with: { $0.scannerOutput.faceScore })
        )
    }
}
