//
//  FaceScannerOutput.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/4/22.
//

import Foundation
import CoreGraphics

struct FaceScannerOutput: Equatable {
    /// Whether there is a valid face in this image
    let isValid: Bool

    /// The quality of the face
    let quality: Float

    init(isValid: Bool) {
        self.isValid = isValid
        self.quality = Float.random(in: Range(uncheckedBounds: (0, 1)))
        
        // TODO(mludowise|IDPROD-3815): Analyze FaceDetector output instead of mocking
    }
}
