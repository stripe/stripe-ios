//
//  OcrPriorsGen.swift
//  CardScan
//
//  Created by xaen on 3/20/20.
//

/// Don't need this, since this is happening on the GPU now ...............

import CoreGraphics
import Foundation

/// This struct represents the logic to generate initiail bounding boxes or priors for our implementation of SSD.
/// We use outputs from two layers of MobileNet V2. In the existing implementation the input size = 300, and
/// repective feature map sizes are 19 x 19 at output layer 1 and 10 x 10 at output layer 2.
struct OcrPriorsGen {

    // At output layer 1 the feature map size = 19 x 19
    static let featureMapSizeBigHeight = 24
    static let featureMapSizeBigWidth = 38

    // At output layer 2, the feature map size = 10 x 10
    static let featureMapSizeSmallHeight = 12
    static let featureMapSizeSmallWidth = 19
    // The feature map size at output layer 2 = 10 x 10 which
    // which is 300 / 10 ~ 32 to make the math simpler
    static let shrinkageBigHeight = 31
    static let shrinkageBigWidth = 31

    // The feature map size at output layer 1 = 19 x 19 which
    // which is 300 / 19 ~ 16 to make the math simpler
    static let shrinkageSmallHeight = 16
    static let shrinkageSmallWidth = 16
    // For each box, the height and width are multiplied
    // by square root of multiple aspect ratios, we use 2 and 3
    static let aspectRatioOne = 3

    // For each activation, since we have 2 aspect ratios,
    // combined with height, and width, this yields a total of
    // 4 combinations of rectangular boxes, we further add two square
    // boxes to make the total number of boxes per activation = 6
    static let noOfPriorsPerLocation = 3

    // For each activation as described above we add two square bounding
    // boxes of size 60, 105 for output layer 1 and 105 and 150 for output
    // layer 2
    static let boxSizeSmallLayerOne = 14
    static let boxSizeBigLayerOne = 30
    static let boxSizeBigLayerTwo = 45

    static func genPriors(
        featureMapSizeHeight: Int,
        featureMapSizeWidth: Int,
        shrinkageHeight: Int,
        shrinkageWidth: Int,
        boxSizeMin: Int,
        boxSizeMax: Int,
        aspectRatioOne: Int,
        noOfPriors: Int
    ) -> [CGRect] {

        let imageHeight = 375
        let imageWidth = 600

        let scaleHeight = Float(imageHeight) / Float(shrinkageHeight)
        let scaleWidth = Float(imageWidth) / Float(shrinkageWidth)

        var boxes = [CGRect]()
        var xCenter: Float
        var yCenter: Float
        var size: Float
        var ratioOne: Float
        var h: Float
        var w: Float

        for j in 0..<featureMapSizeHeight {
            for i in 0..<featureMapSizeWidth {
                xCenter = ((Float(i) + 0.5) / scaleWidth).clamp()
                yCenter = ((Float(j) + 0.5) / scaleHeight).clamp()

                size = Float(boxSizeMin)
                h = (size / Float(imageHeight)).clamp()
                w = (size / Float(imageWidth)).clamp()

                boxes.append(
                    CGRect(
                        x: CGFloat(xCenter),
                        y: CGFloat(yCenter),
                        width: CGFloat(w),
                        height: CGFloat(h)
                    )
                )

                size = sqrt(Float(boxSizeMax) * Float(boxSizeMin))
                h = (size / Float(imageHeight)).clamp()
                w = (size / Float(imageWidth)).clamp()
                ratioOne = sqrt(Float(aspectRatioOne))

                boxes.append(
                    CGRect(
                        x: CGFloat(xCenter),
                        y: CGFloat(yCenter),
                        width: CGFloat(w),
                        height: CGFloat(h * ratioOne)
                    )
                )

                size = Float(boxSizeMin)
                h = (size / Float(imageHeight)).clamp()
                w = (size / Float(imageWidth)).clamp()
                ratioOne = sqrt(Float(aspectRatioOne))

                boxes.append(
                    CGRect(
                        x: CGFloat(xCenter),
                        y: CGFloat(yCenter),
                        width: CGFloat((w).clamp()),
                        height: CGFloat((h * ratioOne).clamp())
                    )
                )

            }
        }
        return boxes
    }

    static func combinePriors() -> [CGRect] {

        let priorsOne = OcrPriorsGen.genPriors(
            featureMapSizeHeight: OcrPriorsGen.featureMapSizeBigHeight,
            featureMapSizeWidth: OcrPriorsGen.featureMapSizeBigWidth,
            shrinkageHeight: OcrPriorsGen.shrinkageSmallHeight,
            shrinkageWidth: OcrPriorsGen.shrinkageSmallWidth,
            boxSizeMin: OcrPriorsGen.boxSizeSmallLayerOne,
            boxSizeMax: OcrPriorsGen.boxSizeBigLayerOne,
            aspectRatioOne: OcrPriorsGen.aspectRatioOne,
            noOfPriors: OcrPriorsGen.noOfPriorsPerLocation
        )

        let priorsTwo = OcrPriorsGen.genPriors(
            featureMapSizeHeight: OcrPriorsGen.featureMapSizeSmallHeight,
            featureMapSizeWidth: OcrPriorsGen.featureMapSizeSmallWidth,
            shrinkageHeight: OcrPriorsGen.shrinkageBigHeight,
            shrinkageWidth: OcrPriorsGen.shrinkageBigWidth,
            boxSizeMin: OcrPriorsGen.boxSizeBigLayerOne,
            boxSizeMax: OcrPriorsGen.boxSizeBigLayerTwo,
            aspectRatioOne: OcrPriorsGen.aspectRatioOne,
            noOfPriors: OcrPriorsGen.noOfPriorsPerLocation
        )

        let priorsCombined = priorsOne + priorsTwo

        return priorsCombined

    }
}

extension Float {
    func clamp(minimum: Float = 0.0, maximum: Float = 1.0) -> Float {
        return max(minimum, min(maximum, self))
    }

}
