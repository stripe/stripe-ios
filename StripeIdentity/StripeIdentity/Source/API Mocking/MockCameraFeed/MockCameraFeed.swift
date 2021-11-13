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

    private var nextImageToReturn: Int = 0

    private var imagePromises: [Promise<CVPixelBuffer>] = []

    private lazy var queue = DispatchQueue(label: "com.stripe.StripeIdentity.MockIdentityDocumentCameraFeed", qos: .userInitiated)

    init(
        imageFiles firstFile: URL,
        _ imageFiles: URL...
    ) {
        ([firstFile] + imageFiles).forEach { url in
            imagePromises.append(loadImage(url: url))
        }
    }

    func loadImage(url: URL) -> Promise<CVPixelBuffer> {
        let promise = Promise<CVPixelBuffer>()
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
        return promise
    }

    func getCurrentFrame() -> Future<CVPixelBuffer> {
        return imagePromises[nextImageToReturn].chained {  [weak self] pixelBuffer in
            if let self = self {
                self.nextImageToReturn = min(
                    self.nextImageToReturn + 1,
                    self.imagePromises.count - 1
                )
            }
            return Promise(value: pixelBuffer)
        }
    }
}
