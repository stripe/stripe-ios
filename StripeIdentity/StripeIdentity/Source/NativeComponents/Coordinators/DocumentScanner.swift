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

    func cancelScan()
}

/**
 Scans a camera feed for a valid identity document.

- Note:
 TODO(mludowise|IDPROD-2482): We haven't implemented the image scanning smarts
 yet. So for now, it's just a timer that returns an image after a few seconds.
 */
final class DocumentScanner: DocumentScannerProtocol {

    static var mockTimeToFindImage: TimeInterval = 3

    enum Classification: Equatable, CaseIterable {
        /// Front of ID Card or Driver's license
        case idCardFront
        /// Back of ID Card or Driver's license
        case idCardBack
        /// Passport
        case passport
    }

    /// The work item for the scanImage request
    private var scanWorkItem: DispatchWorkItem?

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
        assert(Thread.isMainThread, "`scanImage` should only be called from the main thread")

        // If there is an ongoing scan, cancel it
        self.scanWorkItem?.cancel()

        let promise = Promise<CVPixelBuffer>()
        var scanWorkItem: DispatchWorkItem!
        scanWorkItem = DispatchWorkItem(block: {
            // Don't resolve if this scan was cancelled
            guard scanWorkItem.isCancelled == false else {
                return
            }
            promise.resolve(with: pixelBuffer)
        })

        // Book-keep the work item
        self.scanWorkItem = scanWorkItem

        // Execute work item after timer
        queue.asyncAfter(
            deadline: .now() + DocumentScanner.mockTimeToFindImage,
            execute: scanWorkItem
        )
        return promise
    }

    func cancelScan() {
        assert(Thread.isMainThread, "`cancelScan` should only be called from the main thread")
        scanWorkItem?.cancel()
    }
}
