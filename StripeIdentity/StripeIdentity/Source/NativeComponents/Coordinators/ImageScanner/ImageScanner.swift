//
//  ImageScanner.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/4/22.
//

import Foundation

import CoreVideo
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore

protocol ImageScanner {
    associatedtype Output
    typealias Completion = (Output) -> Void

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        cameraSession: CameraSessionProtocol,
        completeOn queue: DispatchQueue,
        completion: @escaping Completion
    )

    func reset()
}

/// Type-erased ImageScanner
struct AnyImageScanner<Output> {
    typealias Completion = (Output) -> Void

    private let _scanImage: (CVPixelBuffer, CameraSessionProtocol, DispatchQueue, @escaping Completion) -> Void
    private let _reset: () -> Void


    init<ImageScannerType: ImageScanner>(
        _ imageScanner: ImageScannerType
    ) where ImageScannerType.Output == Output {
        _scanImage = { pixelBuffer, cameraSession, completeOnQueue, completion in
            imageScanner.scanImage(
                pixelBuffer: pixelBuffer,
                cameraSession: cameraSession,
                completeOn: completeOnQueue,
                completion: completion
            )
        }
        _reset = {
            imageScanner.reset()
        }
    }

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        cameraSession: CameraSessionProtocol,
        completeOn queue: DispatchQueue,
        completion: @escaping Completion
    ) {
        _scanImage(pixelBuffer, cameraSession, queue, completion)
    }

    func reset() {
        _reset()
    }
}
