import Foundation

typealias CardOnFile = CardBase

@available(iOS 11.2, *)
struct VerificationLocalResult {
    let isCardValid: Bool
    let cardValidationFailureReason: String?
    
    func extraData() -> [String: Any] {
        var extraData: [String: Any] = [:]
        
        extraData[VerifyCardViewController.extraDataIsCardValidKey] = isCardValid
        extraData[VerifyCardViewController.extraDataValidationFailureReason] = cardValidationFailureReason
        
        return extraData
    }
}

@available(iOS 11.2, *)
extension ScanBaseViewController {
    func runFraudModels(cardNumber: String, expiryYear: String?, expiryMonth: String?, complete: @escaping ((VerificationLocalResult) -> Void)) {
    
        // todo(stk): put into a utility function at some point
        let bin = String(cardNumber.prefix(6))
        let lastFour = String(cardNumber.suffix(4))
        
        guard let fraudData = self.scanEventsDelegate.flatMap({ $0 as? CardVerifyFraudData }) else {
            // if we got here it means that we scanned the card but
            // that we didn't setup the scanEventsDelegate properly
            // when creating this viewController.
            DispatchQueue.main.async {
                complete(VerificationLocalResult(isCardValid: false, cardValidationFailureReason: "could not find CardVerifyFraudData"))
            }
            return
        }
            
        fraudData.result { scanObject in
            let scanStats = self.getScanStats().toDictionaryForAnalytics()
            
            var scan = scanObject
            scan.ocrResult = CardVerifyFraudData.OcrResult(
                bin: bin,
                lastFour: lastFour,
                expiryMonth: expiryMonth,
                expiryYear: expiryYear
            )
            
            let cardChallenged = CardVerifyFraudData.CardChallenged(lastFour: lastFour, bin: bin, expiryMonth: expiryMonth, expiryYear: expiryYear)
            
            FraudCheckApi.cardVerify(scanObject: scan, scanStats: scanStats, cardChallenged: cardChallenged, debugForceError: nil) {  payload in
                
                let (isCardValid, cardValidationFailureReason) = scan.isCardValid()
                complete(VerificationLocalResult(isCardValid: isCardValid, cardValidationFailureReason: cardValidationFailureReason))
            }
        }
        
    }
}

@available(iOS 11.2, *)
extension ScanBaseViewController {
    func runVerifyPipelineFlashOnly(bin: String, lastFour: String, expiryYear: String?, expiryMonth: String?, complete: @escaping ((VerificationLocalResult) -> Void)) {
        guard let fraudData = self.scanEventsDelegate.flatMap({ $0 as? CardVerifyFraudData }) else {
            // if we got here it means that we scanned the card but
            // that we didn't setup the scanEventsDelegate properly
            // when creating this viewController.
            //
            // We'll invoke the complete function but leave the encrypted
            // payload empty
            DispatchQueue.main.async {
                complete(VerificationLocalResult(
                    isCardValid: false,
                    cardValidationFailureReason: "Images were not captured during scan for analysis"
                ))
            }
            return
        }
        
        fraudData.result { scanObject in
            var scan = scanObject
            
            scan.ocrResult = CardVerifyFraudData.OcrResult(bin: bin, lastFour: lastFour, expiryMonth: expiryMonth, expiryYear: expiryYear)
            let (isCardValid, cardValidationFailureReason) = scan.isCardValidWithFlash()
            complete(VerificationLocalResult(isCardValid: isCardValid, cardValidationFailureReason: cardValidationFailureReason))
        }
    }
}

extension Double {
    func clamp(min: Double, max: Double) -> Double {
        switch (self) {
        case ...min:
            return min
        case max...:
            return max
        default:
            return self
        }
    }
}

extension CardVerifyFraudData.ScanObject {

    private static let LOW_BAD_SCORE = 0.1
    private static let MEDIUM_BAD_SCORE = 0.2
    private static let HIGH_BAD_SCORE = 0.6

    private static let LOW_GOOD_SCORE = 0.05
    private static let MEDIUM_GOOD_SCORE = 0.1
    private static let HIGH_GOOD_SCORE = 0.3
    
    private struct LabelCounts {
        let background: Int
        let americanExpressLogo: Int
        let bankOfAmericaText: Int
        let card: Int
        let chaseLogo: Int
        let chip: Int
        let debitText: Int
        let doveLogoHolo: Int
        let mastercard: Int
        let name: Int
        let pan: Int
        let visa: Int
        let wellsFargoLogo: Int
        let noCard: Int
        
        static func fromObjectFrame(_ frame: [String: Any]) -> LabelCounts? {
            guard let objects = frame["objects"] as? [[String: Any]] else {
                return nil
            }
            
            var labels: [Int: Int] = [:]
            for label in objects.compactMap({ $0["label"] as? Int }) {
                labels[label] = (labels[label] ?? 0) + 1
            }
            
            return LabelCounts(
                background: labels[0] ?? 0,
                americanExpressLogo: labels[1] ?? 0,
                bankOfAmericaText: labels[2] ?? 0,
                card: labels[3] ?? 0,
                chaseLogo: labels[4] ?? 0,
                chip: labels[5] ?? 0,
                debitText: labels[6] ?? 0,
                doveLogoHolo: labels[7] ?? 0,
                mastercard: labels[8] ?? 0,
                name: labels[9] ?? 0,
                pan: labels[10] ?? 0,
                visa: labels[11] ?? 0,
                wellsFargoLogo: labels[12] ?? 0,
                noCard: labels[13] ?? 0
            )
        }
    }
    
    private func checkBrandConsistency(labelCounts: LabelCounts, issuer: CardNetwork) -> Double {
        switch (issuer) {
        case .VISA:
            return Double(labelCounts.mastercard + labelCounts.americanExpressLogo) * CardVerifyFraudData.ScanObject.MEDIUM_BAD_SCORE -
                Double(labelCounts.visa + labelCounts.doveLogoHolo) * CardVerifyFraudData.ScanObject.MEDIUM_GOOD_SCORE
        case .MASTERCARD:
            return Double(labelCounts.visa + labelCounts.doveLogoHolo + labelCounts.americanExpressLogo) * CardVerifyFraudData.ScanObject.MEDIUM_BAD_SCORE -
                Double(labelCounts.mastercard) * CardVerifyFraudData.ScanObject.MEDIUM_GOOD_SCORE
        case .AMEX:
            return Double(labelCounts.visa + labelCounts.doveLogoHolo + labelCounts.mastercard) * CardVerifyFraudData.ScanObject.MEDIUM_BAD_SCORE -
                Double(labelCounts.americanExpressLogo) * CardVerifyFraudData.ScanObject.MEDIUM_GOOD_SCORE
        case .DISCOVER, .UNIONPAY, .JCB, .DINERSCLUB:
            return Double(labelCounts.visa + labelCounts.doveLogoHolo + labelCounts.mastercard + labelCounts.americanExpressLogo) * CardVerifyFraudData.ScanObject.MEDIUM_BAD_SCORE
        case .REGIONAL, .UNKNOWN:
            return 0.0
        }
    }
    
    private func checkTypeConsistency(labelCounts: LabelCounts, type: CardType) -> Double {
        switch (type) {
        case .CREDIT:
            return Double(labelCounts.debitText) * CardVerifyFraudData.ScanObject.MEDIUM_BAD_SCORE
        case .DEBIT, .PREPAID:
            return Double(labelCounts.debitText) * -CardVerifyFraudData.ScanObject.MEDIUM_GOOD_SCORE
        case .UNKNOWN:
            return 0.0
        }
    }

    func didObjectDetectionMismatch() -> Bool {
        // fail for object frames
        guard self.objectFrames.count > 0 else {
            return false
        }
        
        let labelCounts: [Double] = self.objectFrames.compactMap {
            guard let labelCounts = LabelCounts.fromObjectFrame($0) else {
                return nil
            }
            
            let iin = self.ocrResult?.bin
            let issuer = iin.map { CreditCardUtils.determineCardNetwork(cardNumber: $0) } ?? .UNKNOWN
            let type = iin.map { CreditCardUtils.determineCardType(cardNumber: $0) } ?? .UNKNOWN
            
            return 0.299 + self.checkBrandConsistency(labelCounts: labelCounts, issuer: issuer) + self.checkTypeConsistency(labelCounts: labelCounts, type: type)
        }
        .sorted()
        .dropLast(self.objectFrames.count > 1 ? 1 : 0) // throw out the highest score
        
        let average = labelCounts.reduce(0.0) { $0 + $1 } / Double(labelCounts.count)
        return average > 0.3
    }
    
    func didDetectScreen(sdVectorFrames: [[Double]]) -> Bool {
        // fail closed if we don't have any frames or the array results have fewer then
        // two elements
        guard let minCount = sdVectorFrames.map({ $0.count }).min(), minCount >= 3 else {
            return true
        }
        
        // logic copied from the server
        let bobResults = sdVectorFrames.map { ($0[1] + $0[2] - $0[0]) / 8.0 }
        let bobAverage = (bobResults.reduce(0.0) { $0 + $1 }) / Double(bobResults.count)
        let bobScore = (0.3 + bobAverage).clamp(min: 0.0, max: 0.9)
        
        return bobScore > 0.3
    }
    
    func isCardValid() -> (Bool, String?) {
        // filter out images where the flash was forced on, and make sure the frame vector is not empty
        let filteredBobResults = (self.sdVectorFrames.filter { $0.count < 8 || $0[7] == 0.0 })
        guard !filteredBobResults.isEmpty else {
            return (false, "Not enough data")
        }
        
        if !didDetectScreen(sdVectorFrames: filteredBobResults) && !didObjectDetectionMismatch() {
            return (true, nil)
        } else {
            return (false, "Invalid card")
        }
    }
    
    func isCardValidWithFlash() -> (Bool, String?) {
        // filter out images where the flash was forced on, and make sure the frame vector is not empty
        let filteredBobResults = (self.sdVectorFrames.filter { $0.count >= 8 && $0[7] > 0.5 })
        guard !filteredBobResults.isEmpty else {
            return (false, "Not enough data")
        }
        
        if didDetectScreen(sdVectorFrames: filteredBobResults) {
            return (false, "screen_detected")
        } else if didObjectDetectionMismatch() {
            return (false, "object_detection")
        } else {
            return (true, nil)
        }
    }
}


