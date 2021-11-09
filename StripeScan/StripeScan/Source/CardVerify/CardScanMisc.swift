import AVKit

@objc public protocol CaptureOutputDelegate {
    func capture(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
}

@objc public class CreditCard: NSObject {
    @objc public var number: String
    @objc public var expiryMonth: String?
    @objc public var expiryYear: String?
    @objc public var name: String?
    @objc public var image: UIImage?
    @objc public var cvv: String?
    @objc public var postalCode: String?
    
    public init(number: String) {
        self.number = number
    }
    
    @objc public func expiryForDisplay() -> String? {
        guard var month = self.expiryMonth, var year = self.expiryYear else {
            return nil
        }
        
        if month.count == 1 {
            month = "0" + month
        }
        
        if year.count == 4 {
            year = String(year.suffix(2))
        }
        
        return "\(month)/\(year)"
    }
}
