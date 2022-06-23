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

typealias AnyDocumentScanner = AnyImageScanner<DocumentScannerOutput?>

/// Scans a camera feed for a valid identity document.
@available(iOS 13, *)
final class DocumentScanner {

    // MARK: Detectors

    private let idDetector: IDDetector
    private let motionBlurDetector: MotionBlurDetector
    private let barcodeDetector: BarcodeDetector?

    /**
     Initializes a DocumentScanner with detectors.

     - Parameters:
       - idDetector: The IDDetector to classify document images.
       - motionBlurDetector: A motion blur detector to determine if the frame is blurry.
       - barcodeDetector: A barcode detector
     */
    init(
        idDetector: IDDetector,
        motionBlurDetector: MotionBlurDetector,
        barcodeDetector: BarcodeDetector?
    ) {
        self.idDetector = idDetector
        self.motionBlurDetector = motionBlurDetector
        self.barcodeDetector = barcodeDetector
    }

    convenience init(
        idDetectorModel: VNCoreMLModel,
        configuration: Configuration
    ) {
        self.init(
            idDetector: IDDetector(
                model: idDetectorModel,
                configuration: .init(
                    minScore: configuration.idDetectorMinScore,
                    minIOU: configuration.idDetectorMinIOU
                )
            ),
            motionBlurDetector: MotionBlurDetector(
                minIOU: configuration.motionBlurMinIOU,
                minTime: configuration.motionBlurMinDuration
            ),
            barcodeDetector: configuration.backIdCardBarcodeSymbology.map {
                BarcodeDetector(
                    configuration: .init(
                        symbology: $0,
                        timeout: configuration.backIdCardBarcodeTimeout
                    )
                )
            }
        )
    }
}

@available(iOS 13, *)
extension DocumentScanner: ImageScanner {
    typealias Output = DocumentScannerOutput?

    var mlModelMetricsTrackers: [MLDetectorMetricsTrackerProtocol] {
        return [idDetector].compactMap { $0.metricsTracker }
    }

    func scanImage(
        pixelBuffer: CVPixelBuffer,
        cameraProperties: CameraSession.DeviceProperties?
    ) throws -> DocumentScannerOutput? {
        // Scan for ID Document Classification
        guard let idDetectorOutput = try self.idDetector.scanImage(pixelBuffer: pixelBuffer) else {
            return nil
        }

        // Check for motion blur
        let motionBlurOutput = self.motionBlurDetector.determineMotionBlur(
            documentBounds: idDetectorOutput.documentBounds
        )

        // If there's motion blur, reset the timer on the barcode detector.
        // Otherwise, scan for a barcode if this is the back of an ID.
        var barcodeOutput: BarcodeDetectorOutput? = nil
        if let barcodeDetector = self.barcodeDetector,
           idDetectorOutput.classification == .idCardBack {
            barcodeOutput = try barcodeDetector.scanImage(
                pixelBuffer: pixelBuffer,
                regionOfInterest: idDetectorOutput.documentBounds
            )
        }

        return DocumentScannerOutput(
            idDetectorOutput: idDetectorOutput,
            barcode: barcodeOutput,
            motionBlur: motionBlurOutput,
            cameraProperties: cameraProperties
        )
    }

    func reset() {
        motionBlurDetector.reset()
        barcodeDetector?.reset()
        idDetector.metricsTracker?.reset()
    }
}

extension IDDetectorOutput.Classification {
    /**
     Determines if the classification output by the IDDetector matches the
     scanner's desired classification.

     - Parameters:
       - type: The desired document type
       - side: The desired document side

     - Returns: True if this classification matches the desired classification.
     */
    func matchesDocument(
        type: DocumentType,
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
