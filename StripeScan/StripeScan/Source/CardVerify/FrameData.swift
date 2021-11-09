import UIKit

struct FrameData {
    let bin: String?
    let last4: String?
    let expiry: Expiry?
    let numberBoundingBox: CGRect?
    let numberBoxesInFullImageFrame: [CGRect]?
    let croppedCardSize: CGSize
    let squareCardImage: CGImage
    let fullCardImage: CGImage
    let centeredCardState: CenteredCardState?
    let ocrSuccess: Bool
    let uxFrameConfidenceValues: UxFrameConfidenceValues?
    let flashForcedOn: Bool
    
    func toDictForOcrFrame() -> [String: Any] {
        var numberBox: [String: Any]?
        
        if let numberBoundingBox = self.numberBoundingBox {
            numberBox = ["x_min": numberBoundingBox.minX / CGFloat(croppedCardSize.width),
                         "y_min": numberBoundingBox.minY / CGFloat(croppedCardSize.height),
                         "width": numberBoundingBox.width / CGFloat(croppedCardSize.width),
                         "height": numberBoundingBox.height / CGFloat(croppedCardSize.height),
                         "label": -1,
                         "confidence": 1]
        }
  
        var result: [String: Any] = [:]
        result["bin"] = self.bin
        result["last4"] = self.last4
        result["number_box"] = numberBox
        result["exp_month"] = (self.expiry?.month).map { String($0) }
        result["exp_year"] = (self.expiry?.year).map { String($0) }
        
        return result
    }
}
