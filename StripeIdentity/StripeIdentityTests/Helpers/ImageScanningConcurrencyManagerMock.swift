//
//  ImageScanningConcurrencyManagerMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 5/11/22.
//

import Foundation
import CoreVideo
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore
@testable import StripeIdentity

final class ImageScanningConcurrencyManagerMock: ImageScanningConcurrencyManagerProtocol {

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
}
