//
//  CameraExifMetadata.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 4/14/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreMedia
import Foundation
import ImageIO

/// A helper to extract properties from an EXIF metadata dictionary
@_spi(STP) public struct CameraExifMetadata: Equatable {
    public let brightnessValue: Double?
    public let focalLength: Double?
    public let lensModel: String?
}

extension CameraExifMetadata {
    public init?(
        exifDictionary: [CFString: Any]?
    ) {
        guard let exifDictionary = exifDictionary else {
            return nil
        }

        self.init(
            brightnessValue: exifDictionary[kCGImagePropertyExifBrightnessValue] as? Double,
            focalLength: exifDictionary[kCGImagePropertyExifFocalLength] as? Double,
            lensModel: exifDictionary[kCGImagePropertyExifLensModel] as? String
        )
    }

    public init?(
        sampleBuffer: CMSampleBuffer
    ) {
        self.init(
            exifDictionary: CMGetAttachment(
                sampleBuffer,
                key: kCGImagePropertyExifDictionary,
                attachmentModeOut: nil
            ) as? [CFString: Any]
        )
    }
}
