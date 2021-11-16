//
//  DocumentScanner.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/9/21.
//

import CoreVideo
@_spi(STP) import StripeCore

protocol DocumentScannerProtocol: AnyObject {
    func scanImage(
        pixelBuffer: CVPixelBuffer,
        desiredClassification: DocumentScanner.Classification,
        completeOn queue: DispatchQueue
    ) -> Promise<CVPixelBuffer>
}

/**
 Scans a camera feed for a valid identity document.

- Note:
 TODO(mludowise|IDPROD-2482): We haven't implemented the image scanning smarts
 yet. So for now, it's just a timer that returns an image after a few seconds.
 */
final class DocumentScanner: DocumentScannerProtocol {

    enum Classification: Equatable, CaseIterable {
        /// Front of ID Card or Driver's license
        case idCardFront
        /// Back of ID Card or Driver's license
        case idCardBack
        /// Passport
        case passport
    }

    /*
     TODO(mludowise|IDPROD-2482): This will likely eventually return a promise
     that contains information to give the user (e.g. they need to flip their
     card over or move it into frame, etc)
     */
    func scanImage(
        pixelBuffer: CVPixelBuffer,
        desiredClassification: Classification,
        completeOn queue: DispatchQueue
    ) -> Promise<CVPixelBuffer> {
        let promise = Promise<CVPixelBuffer>()
        queue.asyncAfter(deadline: .now() + 3) {
            promise.resolve(with: pixelBuffer)
        }
        return promise
    }
}
