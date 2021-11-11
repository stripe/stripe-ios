//
//  MockCameraFeed.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/9/21.
//

import UIKit

@_spi(STP) import StripeCore

/**
 TODO(mludowise|IDPROD-2774): When we start using a real camera feed, we'll
 probably refactor this mock to something more similar to
 `AVCaptureVideoDataOutput` so it can be used to mock a live camera feed in
 tests. We'll also migrate this to a TestUtil target at that time.

 For now, we just need something to return a pixel buffer to scan for documents.
 */
final class MockIdentityDocumentCameraFeed {

    enum Error: Swift.Error {
        case invalidImage
        case couldNotConvertToBuffer
    }

    private var didReturnFront = false

    private let loadFrontImagePromise = Promise<CVPixelBuffer>()
    private let loadBackImagePromise = Promise<CVPixelBuffer>()

    private lazy var queue = DispatchQueue(label: "com.stripe.StripeIdentity.MockIdentityDocumentCameraFeed", qos: .userInitiated)

    init?(
        frontDocumentImageFile: URL,
        backDocumentImageFile: URL
    ) {
        loadImage(url: frontDocumentImageFile, promise: loadFrontImagePromise)
        loadImage(url: backDocumentImageFile, promise: loadBackImagePromise)
    }

    func loadImage(url: URL, promise: Promise<CVPixelBuffer>) {
        queue.async {
            do {
                let data = try Data(contentsOf: url)
                guard let image = UIImage(data: data) else {
                    promise.reject(with: Error.invalidImage)
                    return
                }
                guard let pixelBuffer = image.convertToBuffer() else {
                    promise.reject(with: Error.couldNotConvertToBuffer)
                    return
                }
                promise.resolve(with: pixelBuffer)
            } catch {
                promise.reject(with: error)
            }
        }
    }

    func getCurrentFrame() -> Future<CVPixelBuffer> {
        guard !didReturnFront else {
            return loadBackImagePromise
        }

        return loadFrontImagePromise.chained { [weak self] pixelBuffer in
            self?.didReturnFront = true

            return Promise(value: pixelBuffer)
        }
    }
}
