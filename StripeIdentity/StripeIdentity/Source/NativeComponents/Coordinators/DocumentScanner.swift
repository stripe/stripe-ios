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
        completeOn queue: DispatchQueue,
        completion: @escaping (CVPixelBuffer) -> Void
    )

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

    private let workerQueue = DispatchQueue(label: "com.stripe.identity.document-scanner")

    // Temporary until scanning smarts are added
    private var mockTimeToFindResult: Date?

    // The work item the `scanImage` completion block is executed in.
    // Used to cancel the scan if needed.
    private var completionWorkItem: DispatchWorkItem?

    /*
     TODO(mludowise|IDPROD-2482): This will likely eventually return a promise
     that contains information to give the user (e.g. they need to flip their
     card over or move it into frame, etc)
     */
    func scanImage(
        pixelBuffer: CVPixelBuffer,
        desiredClassification: Classification,
        completeOn queue: DispatchQueue,
        completion: @escaping (CVPixelBuffer) -> Void
    ) {
        workerQueue.async { [weak self] in
            guard let self = self else { return }

            // Cancel the previous work item if it's still running
            self.completionWorkItem?.cancel()

            // If this is the first call to scanner, start the mock timer
            let now = Date()
            let mockTimeToFindResult = self.mockTimeToFindResult ?? Date(timeInterval: DocumentScanner.mockTimeToFindImage, since: now)
            self.mockTimeToFindResult = mockTimeToFindResult

            // Haven't found classification yet
            guard mockTimeToFindResult <= now else {
                return
            }
            self.mockTimeToFindResult = nil

            // Hold onto a local reference so we can check if it's been cancelled
            var completionWorkItem: DispatchWorkItem!
            completionWorkItem = DispatchWorkItem(block: { [weak self] in
                defer {
                    // Release reference to work item after we're done with it
                    self?.completionWorkItem = nil
                }
                // Ensure the scan has not been cancelled before executing on queue
                guard !completionWorkItem.isCancelled else {
                    return
                }
                completion(pixelBuffer)
            })
            self.completionWorkItem = completionWorkItem
            queue.async(execute: completionWorkItem)
        }
    }

    func cancelScan() {
        workerQueue.async { [weak self] in
            guard let self = self else { return }
            // Reset mock timer
            self.mockTimeToFindResult = nil

            // Cancel completion block and release reference
            self.completionWorkItem?.cancel()
            self.completionWorkItem = nil
        }
    }
}
