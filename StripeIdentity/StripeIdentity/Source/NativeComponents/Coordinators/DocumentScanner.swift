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

protocol DocumentScannerProtocol: AnyObject {
    typealias DocumentType = VerificationPageDataIDDocument.DocumentType
    typealias Completion = (IDDetectorOutput?) -> Void

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        desiredDocumentType: DocumentType,
        desiredDocumentSide: DocumentSide,
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
       - desiredDocumentType: The type of document we're hoping to find in the image
       - desiredDocumentSide: The side of the document we're hoping to find in the image
       - completeOn: DispatchQueue to call the completion block on
       - completion: Executed after the image has been analyzed
     */
    func scanImage(
        pixelBuffer: CVPixelBuffer,
        desiredDocumentType: DocumentType,
        desiredDocumentSide: DocumentSide,
        completeOn queue: DispatchQueue,
        completion: @escaping Completion
    ) {
        workerQueue.async { [weak self] in
            guard let self = self else { return }

            self.idDetector.scanImage(pixelBuffer: pixelBuffer).observe(on: queue) { result in
                switch result {
                case .failure:
                    // TODO(mludowise|IDPROD-2816): log error
                    return
                case .success(let idDetectorOutput):
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
    func matchesDocument(
        type: VerificationPageDataIDDocument.DocumentType,
        side: DocumentSide
    ) -> Bool {
        switch (type, side, self) {
        case (.drivingLicense, .front, .idCardFront),
            (.idCard, .front, .idCardFront),
            (.drivingLicense, .back, .idCardBack),
            (.idCard, .back, .idCardBack),
            (.passport, _, .passport):
            return true
        default:
            return false
        }
    }
}
