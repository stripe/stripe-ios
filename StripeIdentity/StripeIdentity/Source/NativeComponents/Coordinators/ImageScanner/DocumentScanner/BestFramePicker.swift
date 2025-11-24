//
//  BestFramePicker.swift
//  StripeIdentity
//
//  Created by Kenneth Ackerson on 8/21/24.
//

import Foundation
import CoreGraphics
@_spi(STP) import StripeCameraCore

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
        let now = Date()

        if deadline == nil {
            best = Candidate(cgImage: cgImage, output: output, exif: exif, score: score)
            deadline = now.addingTimeInterval(window)
            return .holding(remaining: window, bestScore: score)
        }

        if let current = best, score > current.score {
            best = Candidate(cgImage: cgImage, output: output, exif: exif, score: score)
        }

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
}
