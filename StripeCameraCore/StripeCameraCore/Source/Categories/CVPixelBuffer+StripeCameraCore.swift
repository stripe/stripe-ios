//
//  CVPixelBuffer+StripeCameraCore.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 3/16/22.
//

import CoreVideo
import VideoToolbox

@_spi(STP) public extension CVPixelBuffer {
    func cgImage() -> CGImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(self, options: nil, imageOut: &cgImage)
        return cgImage
    }
}
