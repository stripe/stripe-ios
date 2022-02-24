//
//  IDDetector.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/27/22.
//

import Foundation
import CoreVideo
import Vision
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore

/**
 Scans an image using the IDDetector ML model.
 */
final class IDDetector {

    let model: VNCoreMLModel

    /**
     Initializes an `IDDetector`
     - Parameters:
       - model: The IDDetector ML model loaded into a `VNCoreMLModel`
     */
    init(model: VNCoreMLModel) {
        self.model = model
    }

    /**
     Scans a given image and returns a future that will resolve to the model's
     output. The future will resolve to nil if an identity document could not be
     detected within the image's scanned region.

     Only the center-cropped square region of the image is scanned for an
     identity document.

     - Note:
     This method may take significant time to complete and will block the
     current thread until it's done processing the image. Never call this method
     from the main thread but instead dispatch to a worker queue before calling
     this method.

     - Parameters:
       - pixelBuffer: The image to scan

     - Returns: A future that will resolve to the model's output.
     */
    @available(iOS 13, *)
    func scanImage(
        pixelBuffer: CVPixelBuffer
    ) -> Future<IDDetectorOutput?> {
        assert(!Thread.isMainThread, "`scanImage` should not be called from the main thread")

        let promise = Promise<IDDetectorOutput?>()

        let imageSize = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer
        )

        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            self?.handleRequest(
                request,
                error: error,
                imageSize: imageSize,
                promise: promise
            )
        }
        // The IDDetector model requires a square region as input, so configure
        // the request to only consider the center-cropped region.
        request.imageCropAndScaleOption = .centerCrop

        do {
            try handler.perform([request])
        } catch {
            promise.reject(with: error)
        }

        return promise
    }

    // MARK: - Helpers

    @available(iOS 13, *)
    private func handleRequest(
        _ request: VNRequest,
        error: Error?,
        imageSize: CGSize,
        promise: Promise<IDDetectorOutput?>
    ) {
        if let error = error {
            return promise.reject(with: error)
        }

        /*
         NOTE: Vision changed the return type of `results` from `[Any]?` to
         `[VNObservation]?` without an availability gate. Storing it as an
         intermediate `[Any]?` type and then casting to `[VNObservation]` is the
         only way to satisfy the compiler for all supported OS versions.
         */
        let results: [Any]? = request.results
        guard let observations = results as? [VNObservation] else {
            return promise.resolve(with: nil)
        }

        do {
            /*
             Because the IDDetector model is only scanning the center-cropped
             square region of the original image, the bounding box returned by
             the model is going to be relative to the center-cropped square.
             We need to convert the bounding box into coordinates relative to
             the original image size.
             */
            let output = try IDDetectorOutput(observations: observations).map {
                IDDetectorOutput(
                    classification: $0.classification,
                    documentBounds: $0.documentBounds.convertFromNormalizedCenterCropSquare(
                        toOriginalSize: imageSize
                    ),
                    allClassificationScores: $0.allClassificationScores
                )
            }
            promise.resolve(with: output)
        } catch {
            promise.reject(with: error)
        }
    }
}
