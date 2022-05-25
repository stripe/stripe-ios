//
//  SSDOcrDetect.swift
//  CardScan
//
//  Created by xaen on 3/21/20.
//

import CoreGraphics
import Foundation
import UIKit

/** Documentation for SSD OCR
 
 */

@_spi(STP) public struct SSDOcrDetect {
    var ssdOcrModel: SSDOcr? = nil
    static var priors: [CGRect]? = nil
    
    static var ssdOcrResource = "SSDOcr"
    static let ssdOcrExtension = "mlmodelc"
    
    //SSD Model parameters
    static let sigma: Float = 0.5
    let ssdOcrImageWidth = 600
    let ssdOcrImageHeight = 375
    let probThreshold: Float = 0.45
    let filterThreshold: Float = 0.39
    let iouThreshold: Float = 0.5
    let centerVariance: Float = 0.1
    let sizeVariance: Float = 0.2
    let candidateSize = 200
    let topK = 20
    
    //Statistics about last prediction
    var lastDetectedBoxes: [CGRect] = []
    static var hasPrintedInitError = false
    
    func warmUp() {
        SSDOcrDetect.initializeModels()
        UIGraphicsBeginImageContext(CGSize(width: ssdOcrImageWidth,
                                           height: ssdOcrImageHeight))
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: ssdOcrImageWidth,
                          height: ssdOcrImageHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let ssdOcrModel = ssdOcrModel else{
            return
        }
        if let pixelBuffer = newImage?.pixelBuffer(width: ssdOcrImageWidth,
                                                   height: ssdOcrImageHeight){
            let input = SSDOcrInput(_0: pixelBuffer)
            let _ = try? ssdOcrModel.prediction(input: input)
        }
    }
    
    @_spi(STP) public static func loadModelFromBundle() -> SSDOcr? {
        guard let ssdOcrUrl  = StripeCardScanBundleLocator.resourcesBundle.url(forResource: SSDOcrDetect.ssdOcrResource, withExtension: SSDOcrDetect.ssdOcrExtension) else {
            return nil
        }
        
        return try? SSDOcr(contentsOf: ssdOcrUrl)
    }
    
    init() {
        if SSDOcrDetect.priors == nil{
            SSDOcrDetect.priors = OcrPriorsGen.combinePriors()
        }
       
        guard let ssdOcrModel = SSDOcrDetect.loadModelFromBundle() else {
            return
        }
        
        self.ssdOcrModel = ssdOcrModel
    }
    
    static func initializeModels() {
        if SSDOcrDetect.priors == nil{
            SSDOcrDetect.priors = OcrPriorsGen.combinePriors()
        }
    }
    
    mutating func detectOcrObjects(prediction: SSDOcrOutput, image: UIImage) -> String? {
        var DetectedOcrBoxes = DetectedAllOcrBoxes()
        

        var (scores, boxes, filterArray) = prediction.getScores(filterThreshold: filterThreshold)
        let regularBoxes = prediction.convertLocationsToBoxes(
            locations: boxes,
            priors: SSDOcrDetect.priors ?? OcrPriorsGen.combinePriors(),
            centerVariance: centerVariance,
            sizeVariance: sizeVariance
        )
        let cornerFormBoxes = prediction.centerFormToCornerForm(regularBoxes: regularBoxes)
        
        (scores, boxes) = prediction.filterScoresAndBoxes(
            scores: scores,
            boxes: cornerFormBoxes,
            filterArray:  filterArray,
            filterThreshold: filterThreshold
        )
        
        if scores.isEmpty || boxes.isEmpty{
            return nil
        }
        
        let result: Result = PredictionUtilOcr().predictionUtil(
            scores:scores,
            boxes: boxes,
            probThreshold: probThreshold,
            iouThreshold: iouThreshold,
            candidateSize: candidateSize,
            topK: topK
        )
    
        for idx in 0..<result.pickedBoxes.count {
            DetectedOcrBoxes.allBoxes.append(
                DetectedSSDOcrBox(
                    category: result.pickedLabels[idx],
                    conf: result.pickedBoxProbs[idx],
                    XMin: Double(result.pickedBoxes[idx][0]),
                    YMin: Double(result.pickedBoxes[idx][1]),
                    XMax: Double(result.pickedBoxes[idx][2]),
                    YMax: Double(result.pickedBoxes[idx][3]),
                    imageSize: image.size
                )
            )
        }
        
        if !DetectedOcrBoxes.allBoxes.isEmpty {
            self.lastDetectedBoxes = DetectedOcrBoxes.getBoundingBoxesOfDigits()
        }
        
        if OcrDDUtils.isQuickRead(allBoxes: DetectedOcrBoxes){
            guard let (number, boxes) = OcrDDUtils.processQuickRead(allBoxes: DetectedOcrBoxes) else { return nil }
            self.lastDetectedBoxes = boxes
            return number
        } else {
            guard let (number, boxes) = OcrDDUtils.sortAndRemoveFalsePositives(allBoxes: DetectedOcrBoxes) else { return nil }
            self.lastDetectedBoxes = boxes
            return number
        }
        
        
    }

    mutating func predict(image: UIImage) -> String? {
        
        SSDOcrDetect.initializeModels()
        guard let pixelBuffer = image.pixelBuffer(width: ssdOcrImageWidth,
                                                  height: ssdOcrImageHeight)
        else {
            return nil
                                                    
        }
        
        guard let ocrDetectModel = ssdOcrModel else {
            if !SSDOcrDetect.hasPrintedInitError {
                SSDOcrDetect.hasPrintedInitError = true
            }
            return nil
        }
        
        let input = SSDOcrInput(_0: pixelBuffer)
        
        guard let prediction = try? ocrDetectModel.prediction(input: input) else {
            return nil
        }
        return self.detectOcrObjects(prediction: prediction, image: image)
    }
}
