//
//  DocumentScanner.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/9/21.
//

import CoreVideo
import Vision
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore

/// The classification to look for when scanning an image
enum DesiredDocumentClassification: Equatable, CaseIterable {
    /// Front of ID Card or Driver's license
    case idCardFront
    /// Back of ID Card or Driver's license
    case idCardBack
    /// Passport
    case passport
}

protocol DocumentScannerProtocol: AnyObject {
    typealias Completion = (IDDetectorOutput) -> Void

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        desiredClassification: DesiredDocumentClassification,
        completeOn queue: DispatchQueue,
        completion: @escaping Completion
    )
}

/// Scans a camera feed for a valid identity document.
@available(iOS 13, *)
final class DocumentScanner: DocumentScannerProtocol {
    private let idDetector: IDDetector

    private let workerQueue = DispatchQueue(label: "com.stripe.identity.document-scanner")

    init(idDetector: IDDetector) {
        self.idDetector = idDetector
    }

    convenience init(idDetectorModel: VNCoreMLModel) {
        self.init(idDetector: IDDetector(model: idDetectorModel))
    }
    
    /**
     Scans a camera frame and calls a completion block if the desired
     classification was detected.

     - Parameters:
       - pixelBuffer: Image to scan
       - desiredClassification: The classification we're hoping to find in the image
       - completeOn: DispatchQueue to call the completion block on
       - completion: Executed if the desired classification is detected in the image bounds.
     */
    func scanImage(
        pixelBuffer: CVPixelBuffer,
        desiredClassification: DesiredDocumentClassification,
        completeOn queue: DispatchQueue,
        completion: @escaping Completion
    ) {
        workerQueue.async { [weak self] in
            guard let self = self else { return }

            self.idDetector.scanImage(pixelBuffer: pixelBuffer).observe(on: queue) { result in
                switch result {
                case .success(nil):
                    // No document found
                    return
                case .failure:
                    // TODO(mludowise|IDPROD-2816): log error
                    return
                case .success(.some(let idDetectorOutput)):
                    guard idDetectorOutput.classification.matches(desiredClassification) else {
                        return
                    }

                    completion(idDetectorOutput)
                }
            }
        }
    }
}

extension IDDetectorOutput.Classification {
    /**
     Determines if the classification output by the IDDetector matches the
     scanner's desired classification.

     - Parameters:
       - desiredClassification: The classification the scanner is looking for.

     - Returns: True if this classification matches the desired classification.
     */
    func matches(_ desiredClassification: DesiredDocumentClassification) -> Bool {
        switch (self, desiredClassification) {
        case (.idCardFront, .idCardFront),
             (.idCardBack, .idCardBack),
             (.passport, .passport):
            return true
        default:
            return false
        }
    }
}
