//
//  DocumentScanner.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import CoreVideo
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
import Vision

typealias AnyDocumentScanner = AnyImageScanner<DocumentScannerOutput?>

/// Scans a camera feed for a valid identity document.

final class DocumentScanner {

    // MARK: Detectors

    private let idDetector: IDDetector
    private let motionBlurDetector: MotionBlurDetector
    private let barcodeDetector: BarcodeDetector?
    private let blurDetector: LaplacianBlurDetector
    private let highResImageCropPadding: CGFloat

    /// Initializes a DocumentScanner with detectors.
    ///
    /// - Parameters:
    ///   - idDetector: The IDDetector to classify document images.
    ///   - motionBlurDetector: A motion blur detector to determine if the frame is blurry.
    ///   - barcodeDetector: A barcode detector
    init(
        idDetector: IDDetector,
        motionBlurDetector: MotionBlurDetector,
        barcodeDetector: BarcodeDetector?,
        blurDetector: LaplacianBlurDetector,
        highResImageCropPadding: CGFloat
    ) {
        self.idDetector = idDetector
        self.motionBlurDetector = motionBlurDetector
        self.barcodeDetector = barcodeDetector
        self.blurDetector = blurDetector
        self.highResImageCropPadding = highResImageCropPadding
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
            },
            blurDetector: LaplacianBlurDetector(blurThreshold: configuration.blurThreshold),
            highResImageCropPadding: configuration.highResImageCorpPadding
        )
    }
}

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
        var barcodeOutput: BarcodeDetectorOutput?
        if let barcodeDetector = self.barcodeDetector,
            idDetectorOutput.classification == .idCardBack
        {
            barcodeOutput = try barcodeDetector.scanImage(
                pixelBuffer: pixelBuffer,
                regionOfInterest: idDetectorOutput.documentBounds
            )
        }

        let blurResult: LaplacianBlurDetector.Output = try {
            let originalImage = pixelBuffer.cgImage()
            guard let croppedImage = try originalImage?.cropping(
                toNormalizedRegion: idDetectorOutput.documentBounds,
                withPadding: highResImageCropPadding,
                computationMethod: .maxImageWidthOrHeight
            )
            else {
                return LaplacianBlurDetector.defaultOutput
            }
            return blurDetector.calculateBlurOutput(inputImage: croppedImage)
        }()
        return DocumentScannerOutput(
            idDetectorOutput: idDetectorOutput,
            barcode: barcodeOutput,
            motionBlur: motionBlurOutput,
            cameraProperties: cameraProperties,
            blurResult: blurResult
        )
    }

    func reset() {
        motionBlurDetector.reset()
        barcodeDetector?.reset()
        idDetector.metricsTracker?.reset()
    }
}

extension IDDetectorOutput.Classification {
    /// Determines if the classification output by the IDDetector matches the
    /// scanner's desired classification.
    ///
    /// - Parameters:
    ///   - type: The desired document type
    ///   - side: The desired document side
    ///
    /// - Returns: True if this classification matches the desired classification.
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
