import VideoToolbox
import UIKit

extension UIImage {
    static func grayImage(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        UIColor.gray.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension CGImage {
    
    // Crop a full image
    func croppedImageForSsd(roiRectangle: CGRect) -> (CGImage, CGRect)? {
        
        // add 10% to our ROI rectangle
        let centerX = roiRectangle.origin.x + roiRectangle.size.width * 0.5
        let centerY = roiRectangle.origin.y + roiRectangle.size.height * 0.5
        
        let width = (roiRectangle.size.width * 1.1) < roiRectangle.size.width ? (roiRectangle.size.width * 1.1) : roiRectangle.size.width
        let height = 375.0 * width / 600.0
        let x = centerX - width * 0.5
        let y = centerY - height * 0.5
        
        let ssdRoiRectangle = CGRect(x: x, y: y, width: width, height: height)
        
        if let image = self.cropping(to: ssdRoiRectangle) {
            return (image, ssdRoiRectangle)
        } else if let image = self.cropping(to: roiRectangle) {
            // fall back if the crop was out of bounds
            return (image, roiRectangle)
        }
        
        return nil
    }
    
    // crop a full image
    func squareImageForUxModel(roiRectangle: CGRect) -> CGImage? {
        // add 10% to our ROI rectangle and make it square centered at the ROI rectangle
        let deltaX = roiRectangle.size.width * 0.1
        let deltaY = roiRectangle.size.width + deltaX - roiRectangle.height
        
        let roiPlusBuffer = CGRect(x: roiRectangle.origin.x - deltaX * 0.5,
                                   y: roiRectangle.origin.y - deltaY * 0.5,
                                   width: roiRectangle.size.width + deltaX,
                                   height: roiRectangle.size.height + deltaY)
        
        // if the expanded roi rectangle is too big, fall back to the tight roi rectangle
        return self.cropping(to: roiPlusBuffer) ?? self.cropping(to: roiRectangle)
    }
    
    // This cropping is used by the object detector
    func squareCardImage(roiRectangle: CGRect) -> CGImage? {
        let width = CGFloat(self.width)
        let height = width
        let centerY = (roiRectangle.maxY + roiRectangle.minY) * 0.5
        let cropRectangle = CGRect(x: 0.0, y: centerY - height * 0.5,
                                   width: width, height: height)
        return self.cropping(to: cropRectangle)
    }
    
    func drawBoundingBoxesOnImage(boxes: [(UIColor, CGRect)]) -> UIImage? {
        let image = UIImage(cgImage: self)
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        
        image.draw(at: CGPoint(x: 0,y :0))
        
        UIGraphicsGetCurrentContext()?.setLineWidth(3.0)
        
        for (color, box) in boxes {
            color.setStroke()
            UIRectFrame(box)
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func drawGrayToFillFullScreen(croppedImage: CGImage, targetSize: CGSize) -> CGImage? {
        let image = UIImage(cgImage: croppedImage)
        
        UIGraphicsBeginImageContext(targetSize)
        // Make whole image grey
        UIColor.gray.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))
        // Put in image in the center
        image.draw(in: CGRect(x: 0.0, y: (CGFloat(targetSize.height) - CGFloat(croppedImage.height)) / 2.0, width: CGFloat(croppedImage.width), height: CGFloat(croppedImage.height)))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage?.cgImage
    }

    func toFullScreenAndRoi(previewViewFrame: CGRect, regionOfInterestLabelFrame: CGRect) -> (CGImage, CGRect)? {
        let imageCenterX = CGFloat(self.width) / 2.0
        let imageCenterY = CGFloat(self.height) / 2.0
        
        let imageAspectRatio = CGFloat(self.height) / CGFloat(self.width)
        let previewViewAspectRatio = previewViewFrame.height / previewViewFrame.width
        
        let pointsToPixel: CGFloat = imageAspectRatio > previewViewAspectRatio ? CGFloat(self.width) / previewViewFrame.width : CGFloat(self.height) / previewViewFrame.height

        let cropRatio = CGFloat(16.0) / CGFloat(9.0)
        var fullScreenCropHeight: CGFloat = CGFloat(self.height)
        var fullScreenCropWidth: CGFloat = CGFloat(self.width)
        
        let previewViewHeight = previewViewFrame.height * pointsToPixel
        let previewViewWidth = previewViewFrame.width * pointsToPixel
        
        // Get ratio to convert points to pixels
        let fullScreenImage: CGImage? = {
            // if image is already 16:9, no need to crop to match crop ratio
            ///TODO(jaimepark): make sure this works
            if abs(cropRatio - imageAspectRatio) < 0.0001{
                return self
            }

            // imageAspectRatio not being 16:9 implies image being in landscape
            // get width to first not cut out any card information
            fullScreenCropWidth = previewViewFrame.width * pointsToPixel
            fullScreenCropHeight = fullScreenCropWidth * (16.0 / 9.0)
            let imageHeight = CGFloat(self.height)

            // If 16:9 crop height is larger than the image height itself (i.e. custom formsheet size height is much shorter than the width), crop the image with full height and add grey boxes
            if fullScreenCropHeight > imageHeight {
                guard let croppedImage = self.cropping(to: CGRect(x: imageCenterX - fullScreenCropWidth / 2.0, y: imageCenterY - imageHeight / 2.0, width: fullScreenCropWidth, height: imageHeight)) else { return nil }
                return self.drawGrayToFillFullScreen(croppedImage: croppedImage, targetSize: CGSize(width: fullScreenCropWidth, height: fullScreenCropHeight))
            }

            return self.cropping(to: CGRect(x: imageCenterX - fullScreenCropWidth / 2.0, y: imageCenterY - fullScreenCropHeight / 2.0, width: fullScreenCropWidth, height: fullScreenCropHeight))
        }()

        let roiRect: CGRect? = {
            let roiWidth = regionOfInterestLabelFrame.width * pointsToPixel
            let roiHeight = regionOfInterestLabelFrame.height * pointsToPixel
            
            var roiCenterX = roiWidth / 2.0 + regionOfInterestLabelFrame.origin.x * pointsToPixel
            var roiCenterY = roiHeight / 2.0 + regionOfInterestLabelFrame.origin.y * pointsToPixel

            if fullScreenCropHeight > previewViewHeight {
                roiCenterY += (fullScreenCropHeight - previewViewHeight) / 2.0
            }
            if fullScreenCropWidth > previewViewWidth {
                roiCenterX += (fullScreenCropWidth - previewViewWidth) / 2.0
            }

            return CGRect(x: roiCenterX - roiWidth / 2.0, y: roiCenterY - roiHeight / 2.0, width: roiWidth, height: roiHeight)
        }()

        guard let regionOfInterestRect = roiRect, let fullScreenCgImage = fullScreenImage else { return nil }
        return (fullScreenCgImage, regionOfInterestRect)
    }
}

extension CVPixelBuffer {
    func cgImage() -> CGImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(self, options: nil, imageOut: &cgImage)

        return cgImage
    }
}
