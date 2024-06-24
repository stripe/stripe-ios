//
//  ImageScannerMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 5/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreVideo
import Foundation
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
import XCTest

import CoreMedia
@testable import StripeIdentity

final class ImageScannerMock<Output>: ImageScanner {
    var mlModelMetricsTrackers: [MLDetectorMetricsTrackerProtocol] = []

    var scanResult: Result<Output, Error>

    private(set) var didReset = false

    init(
        scanResult: Result<Output, Error> = .failure(NSError(domain: "", code: 0))
    ) {
        self.scanResult = scanResult
    }

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        sampleBuffer: CMSampleBuffer,
        cameraProperties: StripeCameraCore.CameraSession.DeviceProperties?
    ) -> StripeCore.Future<Output> {
        do {
            return Promise(value: try scanResult.get())
        } catch {
            return Promise(error: error)
        }
    }

    func reset() {
        didReset = true
    }
}

typealias DocumentScannerMock = ImageScannerMock<DocumentScannerOutput?>
typealias FaceScannerMock = ImageScannerMock<FaceScannerOutput>
