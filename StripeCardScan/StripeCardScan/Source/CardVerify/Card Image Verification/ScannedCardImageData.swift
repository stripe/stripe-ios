//
//  ScannedCardImageDataProtocol.swift
//  StripeCardScan
//
//  Created by Jaime Park on 11/21/21.
//

import Foundation
import UIKit

/// Data structure representing an image frame captured during the scanning flow.
struct ScannedCardImageData {
    /// The image of the scanned card after it has been converted from AVCaptureSession to the video preview layer coordinate system
    let previewLayerImage: CGImage
    /// The viewfinder bounds after it has been converted from the AVCaptureSession to the video preview layer coordinate system
    let previewLayerViewfinderRect: CGRect

    init(
        previewLayerImage: CGImage,
        previewLayerViewfinderRect: CGRect
    ) {
        self.previewLayerImage = previewLayerImage
        self.previewLayerViewfinderRect = previewLayerViewfinderRect
    }

    init?(
        captureDeviceImage: CGImage,
        viewfinderRect: CGRect,
        previewViewRect: CGRect
    ) {
        guard
            let previewLayerImage =
                ScannedCardImageData
                .convertToPreviewLayerImage(
                    captureDeviceImage: captureDeviceImage,
                    viewfinderRect: viewfinderRect,
                    previewViewRect: previewViewRect
                ),
            let previewLayerViewfinderRect =
                ScannedCardImageData
                .convertToPreviewLayerRect(
                    captureDeviceImage: captureDeviceImage,
                    viewfinderRect: viewfinderRect,
                    previewViewRect: previewViewRect
                )
        else {
            return nil
        }

        self.init(
            previewLayerImage: previewLayerImage,
            previewLayerViewfinderRect: previewLayerViewfinderRect
        )
    }
}

/// TODO(jaimepark): Update conversion methods to calculate based on only AVCaputureSessionPreviewLayer.
/// Currently, .FullScreenAndRoi returns both the converted image and view finder rect. Once the conversion logic
/// is updated, the params will be updated and these functions will be DRY-ed up.
extension ScannedCardImageData {
    /// Using legacy SDK logic, returns the AVCaptureDevice-to-preview view layer converted image
    static func convertToPreviewLayerImage(
        captureDeviceImage: CGImage,
        viewfinderRect: CGRect,
        previewViewRect: CGRect
    ) -> CGImage? {
        guard
            let (convertedImage, _) =
                captureDeviceImage.toFullScreenAndRoi(
                    previewViewFrame: previewViewRect,
                    regionOfInterestLabelFrame: viewfinderRect
                )
        else {
            return nil
        }
        return convertedImage
    }

    /// Using legacy SDK logic, returns the AVCaptureDevice-to-preview view layer converted view finder rect
    static func convertToPreviewLayerRect(
        captureDeviceImage: CGImage,
        viewfinderRect: CGRect,
        previewViewRect: CGRect
    ) -> CGRect? {
        guard
            let (_, convertedRect) =
                captureDeviceImage.toFullScreenAndRoi(
                    previewViewFrame: previewViewRect,
                    regionOfInterestLabelFrame: viewfinderRect
                )
        else {
            return nil
        }
        return convertedRect
    }
}
