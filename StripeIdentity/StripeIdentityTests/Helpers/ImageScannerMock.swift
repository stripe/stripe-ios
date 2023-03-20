//
//  ImageScannerMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 5/11/22.
//

import Foundation
import XCTest
import CoreVideo
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore
@testable import StripeIdentity

final class ImageScannerMock<Output>: ImageScanner {
    var mlModelMetricsTrackers: [MLDetectorMetricsTrackerProtocol] = []

    var scanResult: Result<Output, Error>

    private(set) var didReset = false

    init(scanResult: Result<Output, Error> = .failure(NSError(domain: "", code: 0))) {
        self.scanResult = scanResult
    }

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        cameraProperties: CameraSession.DeviceProperties?
    ) throws -> Output {
        return try scanResult.get()
    }

    func reset() {
        didReset = true
    }
}

typealias DocumentScannerMock = ImageScannerMock<DocumentScannerOutput?>
typealias FaceScannerMock = ImageScannerMock<FaceScannerOutput>
