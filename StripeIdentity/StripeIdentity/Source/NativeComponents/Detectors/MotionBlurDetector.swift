//
//  MotionBlurDetector.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/18/22.
//
import Foundation
import CoreGraphics
@_spi(STP) import StripeCore

final class MotionBlurDetector {

    struct Output: Equatable {
        let hasMotionBlur: Bool
        let iou: Float?
        let frameCount: Int
    }

    /// Wrap all instance property modifications in a serial queue
    private let serialQueue = DispatchQueue(label: "com.stripe.identity.motion-blur-detector")

    /// IOU threshold of document bounding box between camera frames
    let minIOU: Float

    /// Number of consecutive camera frames the IOU must stay under the threshold
    let minFrameCount: Int


    /// The document bounding box from the last camera frame
    private var lastBoundingBox: CGRect? = nil

    /// The number of consecutive camera frames the bounding box IOU has remained under the threshold
    private var numFramesUnderThreshold: Int = 0

    init(
        minIOU: Float,
        minFrameCount: Int
    ) {
        self.minIOU = minIOU
        self.minFrameCount = minFrameCount
    }

    /**
     Checks if the document has shifted bounds enough to create motion blur.

     - Parameters:
       - documentBounds: The bounds of the document in image coordinates.
     */
    func determineMotionBlur(
         documentBounds: CGRect
     ) -> Output {
         // Perform all operations in serial queue to modify instance properties.
         var output: Output!
         serialQueue.sync {
             defer {
                 lastBoundingBox = documentBounds
             }

             guard let lastBoundingBox = lastBoundingBox else {
                 output = .init(hasMotionBlur: true, iou: nil, frameCount: 0)
                 return
             }

             let iou = IOU(documentBounds, lastBoundingBox)
             guard iou >= minIOU else {
                 numFramesUnderThreshold = 0
                 output = .init(hasMotionBlur: true, iou: iou, frameCount: 0)
                 return
             }

             numFramesUnderThreshold += 1
             output = .init(
                hasMotionBlur: numFramesUnderThreshold < minFrameCount,
                iou: iou,
                frameCount: 0
             )
         }
         return output
     }

    func reset() {
        serialQueue.async { [weak self] in
            self?.lastBoundingBox = nil
            self?.numFramesUnderThreshold = 0
        }
    }
}
