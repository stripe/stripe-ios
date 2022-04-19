//
//  CameraExifMetadata.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 4/14/22.
//

import Foundation
import ImageIO
import CoreMedia

/// A helper to extract properties from an EXIF metadata dictionary
@_spi(STP) public struct CameraExifMetadata {
    public let exifDictionary: [CFString: Any]

    // MARK: - Init

    public init?(exifDictionary: [CFString: Any]?) {
        guard let exifDictionary = exifDictionary else {
            return nil
        }
        self.exifDictionary = exifDictionary
    }

    public init?(sampleBuffer: CMSampleBuffer) {
        self.init(exifDictionary: CMGetAttachment(sampleBuffer, key: kCGImagePropertyExifDictionary, attachmentModeOut: nil) as? [CFString: Any])
    }

    // MARK: - Computed Properties

    public var brightnessValue: Double? {
        return exifDictionary[kCGImagePropertyExifBrightnessValue] as? Double
    }

    public var lensModel: String? {
        return exifDictionary[kCGImagePropertyExifLensModel] as? String
    }

    public var focalLength: Double? {
        return exifDictionary[kCGImagePropertyExifFocalLength] as? Double
    }
}
