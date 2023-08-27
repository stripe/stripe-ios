//
//  LaplacianBlurDetector.swift
//  StripeIdentity
//
//  Created by Chen Cen on 8/22/23.
//

import Accelerate
import Foundation
import Metal
import MetalKit
import MetalPerformanceShaders
@_spi(STP) import StripeCameraCore
import Vision

/// Detector to determine if an image is blurry based on variance of the  laplacian method implemented with Metal.
final class LaplacianBlurDetector {
    struct Output: Equatable {
        let isBlurry: Bool
        let variance: Float
    }

    let blurThreshold: Float

    private let mtlDevice = MTLCreateSystemDefaultDevice()
    lazy var mtlCommandQueue = {
        return mtlDevice?.makeCommandQueue()
    }()

    init(blurThreshold: Float) {
        self.blurThreshold = blurThreshold
    }

    func calculateBlurOutput(inputImage: CGImage) -> Output {
        guard let mtlCommandQueue = self.mtlCommandQueue, let mtlDevice = self.mtlDevice
        else{
            return Output(isBlurry: false, variance: 0)
        }
        // Create a command buffer for the transformation pipeline
        let commandBuffer = mtlCommandQueue.makeCommandBuffer()!
        // These are the two built-in shaders we will use
        let laplacian = MPSImageLaplacian(device: mtlDevice)
        let meanAndVariance = MPSImageStatisticsMeanAndVariance(device: mtlDevice)
        // Load the captured pixel buffer as a texture
        let textureLoader = MTKTextureLoader(device: mtlDevice)
        let sourceTexture = try! textureLoader.newTexture(cgImage: inputImage, options: nil)
        // Create the destination texture for the laplacian transformation
        let lapDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat, width: sourceTexture.width, height: sourceTexture.height, mipmapped: false)
        lapDesc.usage = [.shaderWrite, .shaderRead]
        let lapTex = mtlDevice.makeTexture(descriptor: lapDesc)!
        // Encode this as the first transformation to perform
        laplacian.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: lapTex)
        // Create the destination texture for storing the variance.
        let varianceTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat, width: 2, height: 1, mipmapped: false)
        varianceTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        let varianceTexture = mtlDevice.makeTexture(descriptor: varianceTextureDescriptor)!
        // Encode this as the second transformation
        meanAndVariance.encode(commandBuffer: commandBuffer, sourceTexture: lapTex, destinationTexture: varianceTexture)
        // Run the command buffer on the GPU and wait for the results
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Output would is two arrays of 4 values for the mean and variant of [r, g, b, a] channel
        // return the mean of [r, g, b] as a indicator of blurriness
        var result = [SIMD4<UInt8>](repeatElement(SIMD4<UInt8>(repeating: 0), count: 2))
        let region = MTLRegionMake2D(0, 0, 2, 1)
        varianceTexture.getBytes(&result, bytesPerRow: 1 * 2 * 4, from: region, mipmapLevel: 0)

        let variants = result[0]

        let rgbVariantsSum = Float(variants[0]) + Float(variants[1]) + Float(variants[2])
        let variantsAvg = rgbVariantsSum / 3.0

        return Output(isBlurry: variantsAvg < blurThreshold, variance: variantsAvg)
    }
}

extension AccelerateMutableBuffer where Element == Float {
    var variance: Float {

        var mean = Float.nan
        var standardDeviation = Float.nan

        self.withUnsafeBufferPointer {
            vDSP_normalize($0.baseAddress!, 1,
                           nil, 1,
                           &mean, &standardDeviation,
                           vDSP_Length(self.count))
        }

        return standardDeviation * standardDeviation
    }
}
