//
//  ImageScanningConcurrencyManagerMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 5/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreGraphics
import CoreVideo
import Foundation
@_spi(InternalOnlyAPI) import StripeCameraCore
@_spi(InternalOnlyAPI) import StripeCore

import CoreMedia
@testable import StripeIdentity

final class ImageScanningConcurrencyManagerMock: ImageScanningConcurrencyManagerProtocol {

    var mockAverageFPSMetric: Double?
    var mockNumFramesScannedMetric: Int = 0

    private(set) var didReset = false
    private(set) var resetCallCount = 0
    private(set) var scanCallCount = 0
    private var completion: ((Any?) -> Void)?
    var automaticallyCompletesReset = true
    private var resetCompletions: [() -> Void] = []
    private var readinessCompletions: [() -> Void] = []

    func scanImage<ScannerOutput>(
        with scanner: AnyImageScanner<ScannerOutput>,
        pixelBuffer: CVPixelBuffer,
        sampleBuffer: CMSampleBuffer,
        cameraSession: CameraSessionProtocol,
        completeOn completionQueue: DispatchQueue,
        shouldScan: @escaping () -> Bool,
        completion: @escaping (ScannerOutput, CGImage, CameraExifMetadata?) -> Void
    ) {
        guard shouldScan(), let image = pixelBuffer.cgImage() else {
            return
        }
        scanCallCount += 1
        let exifMetadata = CameraExifMetadata(sampleBuffer: sampleBuffer)
        self.completion = { output in
            guard let output = output as? ScannerOutput else {
                return
            }
            completion(output, image, exifMetadata)
        }
    }

    func respondToScan(output: Any?) {
        completion?(output)
    }

    func reset<ScannerOutput>(
        with scanner: AnyImageScanner<ScannerOutput>,
        completeOn queue: DispatchQueue,
        completion: @escaping () -> Void
    ) {
        didReset = true
        resetCallCount += 1
        let reset = {
            scanner.reset()
            completion()
        }
        if automaticallyCompletesReset {
            reset()
        } else {
            resetCompletions.append(reset)
        }
    }

    func completePendingResets() {
        let completions = resetCompletions
        resetCompletions.removeAll()
        completions.forEach { $0() }
        if resetCompletions.isEmpty {
            let ready = readinessCompletions
            readinessCompletions.removeAll()
            ready.forEach { $0() }
        }
    }

    func whenReady<ScannerOutput>(
        with scanner: AnyImageScanner<ScannerOutput>,
        completeOn queue: DispatchQueue,
        completion: @escaping () -> Void
    ) {
        if resetCompletions.isEmpty {
            completion()
        } else {
            readinessCompletions.append(completion)
        }
    }

    func getPerformanceMetrics(
        completeOn queue: DispatchQueue,
        completion: @escaping (_ averageFPS: Double?, _ numFramesScanned: Int) -> Void
    ) {
        completion(mockAverageFPSMetric, mockNumFramesScannedMetric)
    }
}
