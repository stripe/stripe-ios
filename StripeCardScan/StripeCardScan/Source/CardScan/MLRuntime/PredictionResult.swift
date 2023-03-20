//
//  PredictionResult.swift
//  CardScan
//
//  Created by Sam King on 11/16/18.
//
import CoreGraphics
import Foundation
import UIKit

//
// The PredictionResult includes images of the bin and the last four. The OCR model returns clusters of 4 digits for
// the number so we use only the first 4 for the bin and the full last 4 as a single image
//
struct PredictionResult {
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let numberBoxes: [CGRect]
    let number: String
    let cvvBoxes: [CGRect]
    
    func bin() -> String {
        return String(number.prefix(6))
    }
    
    func last4() -> String {
        return String(number.suffix(4))
    }
    
    static func translateBox(from modelSize: CGSize, to imageSize: CGSize, for box: CGRect) -> CGRect {
        let boxes = translateBoxes(from: modelSize, to: imageSize, for: [box])
        return boxes.first!
    }
    
    static func translateBoxes(from modelSize: CGSize, to imageSize: CGSize, for boxes: [CGRect]) -> [CGRect] {
        let scaleX = imageSize.width / modelSize.width
        let scaleY = imageSize.height / modelSize.height
        
        return boxes.map { CGRect(x: $0.origin.x * scaleX, y: $0.origin.y * scaleY, width: $0.size.width * scaleX, height: $0.size.height * scaleY) }
    }
    
    func translateNumber(to originalImage: CGImage) -> [CGRect] {
        let scaleX = CGFloat(originalImage.width) / self.cardWidth
        let scaleY = CGFloat(originalImage.height) / self.cardHeight
        
        return self.numberBoxes.map { CGRect(x: $0.origin.x * scaleX, y: $0.origin.y * scaleY, width: $0.size.width * scaleX, height: $0.size.height * scaleY) }
    }
    
    func extractImagePng(from image: CGImage, for box: CGRect) -> String? {
        let uiImage = image.cropping(to: box).map { UIImage(cgImage: $0) }
        return uiImage.flatMap { $0.pngData()?.base64EncodedString() }
    }
    
    func resizeImage(image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: size.width, height: size.height))
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
