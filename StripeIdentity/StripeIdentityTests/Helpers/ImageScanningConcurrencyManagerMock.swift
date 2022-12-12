//
//  ImageScanningConcurrencyManagerMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 5/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreVideo
import Foundation
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore

@testable import StripeIdentity

final class ImageScanningConcurrencyManagerMock: ImageScanningConcurrencyManagerProtocol {

    var mockAverageFPSMetric: Double?
    var mockNumFramesScannedMetric: Int = 0

    private(set) var didReset = false
    private var completion: ((Any?) -> Void)?

    func scanImage<ScannerOutput>(
        with scanner: AnyImageScanner<ScannerOutput>,
        pixelBuffer: CVPixelBuffer,
        cameraSession: CameraSessionProtocol,
        completeOn completionQueue: DispatchQueue,
        completion: @escaping (ScannerOutput) -> Void
    ) {
        self.completion = { output in
            guard let output = output as? ScannerOutput else {
                return
            }
            completion(output)
        }
    }

    func respondToScan(output: Any?) {
        completion?(output)
    }

    func reset() {
        didReset = true
    }

    func getPerformanceMetrics(
        completeOn queue: DispatchQueue,
        completion: @escaping (_ averageFPS: Double?, _ numFramesScanned: Int) -> Void
    ) {
        completion(mockAverageFPSMetric, mockNumFramesScannedMetric)
    }
}
