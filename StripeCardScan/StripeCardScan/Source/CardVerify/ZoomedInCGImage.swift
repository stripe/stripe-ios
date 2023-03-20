//
//  ZoomedInCGImage.swift
//  CardScan
//
//  Created by Jaime Park on 6/19/20.
//

import UIKit

class ZoomedInCGImage {
    private let image: CGImage
    private let imageWidth: CGFloat
    private let imageHeight: CGFloat
    private let imageMidHeight: CGFloat
    private let imageMidWidth: CGFloat
    private let imageCenterMinX: CGFloat
    private let imageCenterMaxX: CGFloat
    private let imageCenterMinY: CGFloat
    private let imageCenterMaxY: CGFloat

    private let finalCropWidth: CGFloat = 448.0
    private let finalCropHeight: CGFloat = 448.0
    private let cropQuarterWidth: CGFloat = 112.0 // finalCropWidth / 4
    private let cropQuarterHeight: CGFloat = 112.0 // finalCropHeight / 4

    init(image: CGImage) {
        self.image = image
        self.imageWidth = CGFloat(image.width)
        self.imageHeight = CGFloat(image.height)
        self.imageMidHeight = imageHeight / 2.0
        self.imageMidWidth = imageWidth / 2.0
        self.imageCenterMinX = imageMidWidth - cropQuarterWidth
        self.imageCenterMaxX = imageMidWidth + cropQuarterWidth
        self.imageCenterMinY = imageMidHeight - cropQuarterHeight
        self.imageCenterMaxY = imageMidHeight + cropQuarterHeight
    }

    // Create a zoomed-in image by resizing image pieces in a 3x3 grid, row by row with createResizeLayer
    func zoomedInImage() -> UIImage? {
        guard let topLayer = createResizeLayer(yMin: 0.0, imageHeight: imageCenterMinY, cropHeight: cropQuarterHeight) else { return nil }
        guard let midLayer = createResizeLayer(yMin: imageCenterMinY, imageHeight: cropQuarterHeight * 2, cropHeight: cropQuarterHeight * 2) else { return nil }
        guard let bottomLayer = createResizeLayer(yMin: imageCenterMaxY, imageHeight: imageCenterMinY,  cropHeight: cropQuarterHeight) else { return nil }

        let zoomedImageSize = CGSize(width: finalCropWidth, height: finalCropHeight)
        UIGraphicsBeginImageContextWithOptions(zoomedImageSize, true, 1.0)

        topLayer.draw(in: CGRect(x: 0.0, y: 0.0, width: finalCropWidth, height: cropQuarterHeight))
        midLayer.draw(in: CGRect(x: 0.0, y: cropQuarterHeight, width: finalCropWidth, height: cropQuarterHeight * 2))
        bottomLayer.draw(in: CGRect(x: 0.0, y: cropQuarterHeight * 3, width: finalCropWidth, height: cropQuarterHeight))

        let zoomedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return zoomedImage
    }

    // Resize layer starting at image height coordinate (yMin) with the height within the image (imageHeight) resizing to the input cropping height (cropHeight)
    private func createResizeLayer(yMin: CGFloat, imageHeight: CGFloat, cropHeight: CGFloat) -> UIImage? {
        let leftCropRect = CGRect(x: 0.0, y: yMin, width: imageCenterMinX, height: imageHeight)
        let midCropRect = CGRect(x: imageCenterMinX, y: yMin, width: cropQuarterWidth * 2, height: imageHeight)
        let rightCropRect = CGRect(x: imageCenterMaxX, y: yMin, width: imageCenterMinX, height: imageHeight)

        guard let leftCropImage = self.image.cropping(to: leftCropRect), let leftResizedImage = resize(image: leftCropImage, targetSize: CGSize(width: cropQuarterWidth, height: cropHeight)) else { return nil }

        guard let midCropImage = self.image.cropping(to: midCropRect), let midResizedImage = resize(image: midCropImage, targetSize: CGSize(width: cropQuarterWidth * 2, height: cropHeight)) else { return nil }

        guard let rightCropImage = self.image.cropping(to: rightCropRect), let rightResizedImage = resize(image: rightCropImage, targetSize: CGSize(width: cropQuarterWidth, height: cropHeight)) else { return nil }

        let layerSize = CGSize(width: finalCropWidth, height: cropHeight)
        UIGraphicsBeginImageContextWithOptions(layerSize, false, 1.0)

        leftResizedImage.draw(in: CGRect(x: 0.0, y: 0.0, width: cropQuarterWidth, height: cropHeight))
        midResizedImage.draw(in: CGRect(x: cropQuarterWidth, y: 0.0, width: cropQuarterWidth * 2, height: cropHeight))
        rightResizedImage.draw(in: CGRect(x: cropQuarterWidth * 3, y: 0.0, width: cropQuarterWidth, height: cropHeight))

        let layerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return layerImage
    }

    private func resize(image: CGImage, targetSize: CGSize) -> UIImage? {
        let image = UIImage(cgImage: image)
        let rect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)

        UIGraphicsBeginImageContextWithOptions(targetSize, true, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
