//
//  SSDCreditCardOcr.swift
//  CardScan
//
//  Created by xaen on 5/15/20.
//
import UIKit

@available(iOS 11.2, *)
public class SSDCreditCardOcr: CreditCardOcrImplementation {
    let ocr: OcrDD
    
    public override init(dispatchQueueLabel: String) {
        ocr = OcrDD()
        super.init(dispatchQueueLabel: dispatchQueueLabel)
    }
    
    public override func recognizeCard(in fullImage: CGImage, roiRectangle: CGRect) -> CreditCardOcrPrediction {

        guard let (image, ocrRoiRectangle) = fullImage.croppedImageForSsd(roiRectangle: roiRectangle)
            else {
                return CreditCardOcrPrediction.emptyPrediction(cgImage: fullImage)
        }
                
        let startTime = Date()
        let number = ocr.perform(croppedCardImage: image)
        let duration = -startTime.timeIntervalSinceNow
        let numberBoxes = ocr.lastDetectedBoxes
        
        self.computationTime += duration
        self.frames += 1
        return CreditCardOcrPrediction(image: image,
                                       ocrCroppingRectangle: ocrRoiRectangle,
                                       number: number, expiryMonth: nil,
                                       expiryYear: nil, name: nil, computationTime: duration,
                                       numberBoxes: numberBoxes, expiryBoxes: nil, nameBoxes: nil)
    }
}
