//
//  BestFramePicker.swift
//  StripeIdentity
//
//  Created by Kenneth Ackerson on 8/21/24.
//

import CoreGraphics
import Foundation
@_spi(InternalOnlyAPI) import StripeCameraCore

final class BestFramePicker {
    struct Candidate {
        let cgImage: CGImage
        let output: DocumentScannerOutput
        let exif: CameraExifMetadata?
        let score: Float
    }

    enum State {
        case idle
        case holding(remaining: TimeInterval, bestScore: Float)
        case picked(Candidate)
    }

    private let window: TimeInterval
    private var deadline: Date?
    private var best: Candidate?

    init(window: TimeInterval = 1.0) {
        self.window = window
    }

    func reset() {
        deadline = nil
        best = nil
    }

    func consider(cgImage: CGImage,
                  output: DocumentScannerOutput,
                  exif: CameraExifMetadata?,
                  score: Float) -> State {
        func deadlineCheck() -> State {
            guard let deadline else { return .idle }
            let remaining = deadline.timeIntervalSince(now)
            if remaining <= 0 {
                let picked = best
                reset()
                if let picked { return .picked(picked) }
                return .idle
            } else {
                return .holding(remaining: remaining, bestScore: best?.score ?? 0)
            }
        }
        let now = Date()

        if deadline == nil {
            best = Candidate(cgImage: cgImage, output: output, exif: exif, score: score)
            deadline = now.addingTimeInterval(window)

            return deadlineCheck()
        }

        if let current = best, score > current.score {
            best = Candidate(cgImage: cgImage, output: output, exif: exif, score: score)
        }

        return deadlineCheck()
    }
}

/// Retains a fallback for each document side until the capture session is reset.
/// Unlike the successful capture window, this includes frames rejected for blur.
final class DocumentFrameCache {
    private static let minimumScoreImprovement: Float = 0.02
    private var candidates: [DocumentSide: BestFramePicker.Candidate] = [:]

    func consider(
        cgImage: CGImage,
        output: DocumentScannerOutput,
        exif: CameraExifMetadata?,
        side: DocumentSide
    ) {
        let bounds = output.getDocumentBounds()
        guard output.matchesDocument(side: side),
            bounds.origin.x.isFinite,
            bounds.origin.y.isFinite,
            bounds.size.width.isFinite,
            bounds.size.height.isFinite,
            bounds.size.width > 0,
            bounds.size.height > 0,
            CGRect.normalizedBounds.contains(bounds)
        else {
            return
        }

        let score = output.timeoutQualityScore(side: side)
        guard score.isFinite else {
            return
        }
        if let current = candidates[side] {
            // Allow one rounding step when comparing an improvement of exactly 0.02.
            let minimumScore = (current.score + Self.minimumScoreImprovement).nextDown
            guard score >= minimumScore else {
                return
            }
        }

        candidates[side] = .init(cgImage: cgImage, output: output, exif: exif, score: score)
    }

    func bestCandidate(for side: DocumentSide) -> BestFramePicker.Candidate? {
        return candidates[side]
    }

    func reset() {
        candidates.removeAll()
    }
}
