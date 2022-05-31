//
//  MockFaceScanner.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/4/22.
//

import CoreVideo
import Vision
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore

typealias AnyFaceScanner = AnyImageScanner<FaceScannerOutput>

final class MockFaceScanner: ImageScanner {
    typealias Output = FaceScannerOutput

    static var mockTimeToFindFace: TimeInterval = 0.1

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        cameraProperties: CameraSession.DeviceProperties?
    ) throws -> Output {
        // Mocks blocking the current thread for the amount of time it takes to scan an image
        Thread.sleep(forTimeInterval: MockFaceScanner.mockTimeToFindFace)
        return .init(isValid: true)
    }

    func reset() {
        // Do nothing
    }
}
