/**
 This is a debug view controller not meant for public consumption.
 */
import UIKit

@available(iOS 11.2, *)
open class VerifyScanCardLocalFlashViewController: VerifyCardViewController {
    
    open override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    open override func onScannedCard(number: String, expiryYear: String?, expiryMonth: String?, scannedImage: UIImage?) {
        let bin = String(number.prefix(6))
        let lastFour = String(number.suffix(4))
   
        let card = CreditCard(number: number)
        card.expiryMonth = expiryMonth
        card.expiryYear = expiryYear
        card.name = predictedName
        card.image = scannedImage
        
        runVerifyPipelineFlashOnly(bin: bin, lastFour: lastFour, expiryYear: expiryYear, expiryMonth: expiryMonth) { verificationResult in
            
            self.verifyCardDelegate?.fraudModelResultsVerifyCard(viewController: self, creditCard: card, extraData: verificationResult.extraData())
        }
    }
}
