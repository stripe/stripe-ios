import AVKit

protocol CaptureOutputDelegate {
    func capture(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
}

class CreditCard: NSObject {
    var number: String
    var expiryMonth: String?
    var expiryYear: String?
    var name: String?
    var image: UIImage?
    var cvv: String?
    var postalCode: String?
    
    init(number: String) {
        self.number = number
    }
    
    func expiryForDisplay() -> String? {
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
