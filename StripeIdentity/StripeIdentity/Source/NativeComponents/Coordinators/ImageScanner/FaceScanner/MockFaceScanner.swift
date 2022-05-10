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

    private var startFindingFace: Date?

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        cameraSession: CameraSessionProtocol,
        completeOn completionQueue: DispatchQueue,
        completion: @escaping Completion
    ) {
        let wrappedCompletion: Completion = { output in
            completionQueue.async {
                completion(output)
            }
        }

        if startFindingFace == nil {
            startFindingFace = Date()
        }

        guard let startFindingFace = startFindingFace,
              Date().timeIntervalSince(startFindingFace) >= MockFaceScanner.mockTimeToFindFace
        else {
            wrappedCompletion(.init(isValid: false))
            return
        }

        wrappedCompletion(.init(isValid: true))
    }

    func reset() {
        startFindingFace = nil
    }
}
