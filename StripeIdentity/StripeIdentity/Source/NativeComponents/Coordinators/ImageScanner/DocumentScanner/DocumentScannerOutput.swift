//
//  DocumentScannerOutput.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 3/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCameraCore

/// Consolidated output from all ML models / detectors that make up document
/// scanning. The combination of this output will determine if the image captured
/// is high enough quality to accept and whether the result matches a document side.
enum DocumentScannerOutput: Equatable {
    // Result with legacy detectors
    case legacy(IDDetectorOutput, BarcodeDetectorOutput?, MotionBlurDetector.Output, CameraSession.DeviceProperties?, LaplacianBlurDetector.Output)

    var idDetectorOutput: IDDetectorOutput {
        switch self {
        case .legacy(let detectorOutput, _, _, _, _):
            return detectorOutput
        }
    }

    var cameraProperties: CameraSession.DeviceProperties? {
        switch self {
        case .legacy(_, _, _, let cameraProperties, _):
            return cameraProperties
        }
    }

    var barcode: BarcodeDetectorOutput? {
        switch self {
        case .legacy(_, let barcode, _, _, _):
            return barcode
        }
    }

    /// A check that stops the automatic capture of a frame.
    enum CaptureBlocker: Equatable {
        case wrongDocument
        case tooClose
        case tooFar
        case blurry
        case motionBlur
        case adjustingFocus
    }

    /// Returns the first check that stops the automatic capture of this frame,
    /// or `nil` if the frame can be captured. The scanning hint is built from
    /// the same result, so the hint and the capture decision agree.
    /// - Parameters:
    ///   - side: Side of the desired document.
    func captureBlocker(side: DocumentSide) -> CaptureBlocker? {
        switch self {
        case let .legacy(idDetectorOutput, barcode, motionBlur, cameraProperties, blurResult):
            guard idDetectorOutput.classification.matchesDocument(side: side) else {
                return .wrongDocument
            }
            switch idDetectorOutput.computeZoomLevel() {
            case .tooClose:
                return .tooClose
            case .tooFar:
                return .tooFar
            case .ok:
                break
            }
            if blurResult.isBlurry {
                return .blurry
            }
            // A barcode that is clear enough to decode is good enough, even
            // while the camera moves or focuses.
            if barcode?.hasBarcode == true {
                return nil
            }
            if motionBlur.hasMotionBlur {
                return .motionBlur
            }
            if cameraProperties?.isAdjustingFocus == true {
                return .adjustingFocus
            }
            return nil
        }
    }

    /// Determines if the document is high quality and matches the desired
    /// document type and side.
    /// - Parameters:
    ///   - side: Side of the desired document.
    func isHighQuality(
        side: DocumentSide
    ) -> Bool {
        return captureBlocker(side: side) == nil
    }

    func matchesDocument(
        side: DocumentSide
    ) -> Bool {
        return idDetectorOutput.classification.matchesDocument(side: side)
    }

    func getDocumentBounds() -> CGRect {
        return idDetectorOutput.documentBounds
    }

    func getAllClassificationScores() -> [IDDetectorOutput.Classification: Float] {
        return idDetectorOutput.allClassificationScores
    }

    func qualityScore(side: DocumentSide) -> Float {
        switch self {
        case let .legacy(idDetectorOutput, _, motionBlur, _, _):
            var components: [Float] = []

            let scores = idDetectorOutput.allClassificationScores
            let classificationScore: Float = {
                switch side {
                case .front:
                    let front = scores[.idCardFront] ?? 0
                    let passport = scores[.passport] ?? 0
                    return max(front, passport)
                case .back:
                    return scores[.idCardBack] ?? 0
                }
            }()
            components.append(classificationScore)

            if let iou = motionBlur.iou {
                components.append(iou)
            }

            let total = components.reduce(0, +)
            let score: Float = components.isEmpty ? 0 : total / Float(components.count)

            return score
        }
    }
}
