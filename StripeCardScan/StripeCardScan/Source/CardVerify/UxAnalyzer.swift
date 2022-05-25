//
//  Created by Sam King on 3/20/20.
//  Copyright © 2020 Sam King. All rights reserved.
//
import UIKit

@_spi(STP) public class UxAnalyzer: CreditCardOcrImplementation {
    var uxModel: UxModel?
    let ocr: CreditCardOcrImplementation
    
    init(with ocr: CreditCardOcrImplementation) {
        self.ocr = ocr
        uxModel = UxAnalyzer.loadModelFromBundle()
        super.init(dispatchQueue: ocr.dispatchQueue)
    }
    
    @_spi(STP) public static func loadModelFromBundle() -> UxModel? {
        let bundle = StripeCardScanBundleLocator.resourcesBundle
        guard let url = bundle.url(forResource: "UxModel", withExtension: "mlmodelc") else {
            return nil
        }
        
        return try? UxModel(contentsOf: url)
    }
    
    override func recognizeCard(in fullImage: CGImage, roiRectangle: CGRect) -> CreditCardOcrPrediction {
        guard let imageForUxModel = fullImage.squareImageForUxModel(roiRectangle: roiRectangle),
              let uxModelPixelBuf = UIImage(cgImage: imageForUxModel).pixelBuffer(width: 224, height: 224) else {
            return CreditCardOcrPrediction.emptyPrediction(cgImage: fullImage)
        }
        
        // we already have parallel inference at the analyzer level so no need to run this prediction
        // in parallel with the OCR prediction. Plus, this is iOS so the uxmodel prediction will be fast
        guard let uxModel = uxModel, let prediction = try? uxModel.prediction(input1: uxModelPixelBuf) else {
            return CreditCardOcrPrediction.emptyPrediction(cgImage: fullImage)
        }
        
        return ocr.recognizeCard(in: fullImage, roiRectangle: roiRectangle).with(uxPrediction: prediction)
    }
}

extension UxModelOutput {
    func argMax() -> Int {
        return self.argAndValueMax().0
    }
    
    func argAndValueMax() -> (Int, Double) {
        var maxIdx = -1
        var maxValue = NSNumber(value: -1.0)
        for idx in 0..<3 {
            let index: [NSNumber] = [NSNumber(value: idx)]
            let value = self.output1[index]
            if value.doubleValue > maxValue.doubleValue {
                maxIdx = idx
                maxValue = value
            }
        }
        
        return (maxIdx, maxValue.doubleValue)
    }
    
    func cardCenteredState() -> CenteredCardState {
        switch self.argMax() {
        case 0:
            return .nonNumberSide
        case 2:
            return .numberSide
        default:
            return .noCard
        }
    }
    
    func confidenceValues() -> (Double, Double, Double)? {
        let idxRange = 0..<3
        let indexValues = idxRange.map { [NSNumber(value: $0)] }
        var confidenceValues = indexValues.map { self.output1[$0].doubleValue }
        
        guard let pan = confidenceValues.popLast(), let noCard = confidenceValues.popLast(), let noPan = confidenceValues.popLast() else {
            return nil
        }
        
        return (pan, noPan, noCard)
    }
}
