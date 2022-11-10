//
//  CVPixelBuffer+StripeCameraCore.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 3/16/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreVideo
import VideoToolbox

@_spi(STP) extension CVPixelBuffer {
    public func cgImage() -> CGImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(self, options: nil, imageOut: &cgImage)
        return cgImage
    }
}
