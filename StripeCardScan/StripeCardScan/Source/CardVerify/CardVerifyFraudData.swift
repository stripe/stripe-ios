import Foundation

class CardVerifyFraudData: CardScanFraudData {
    // one subtlety we have is that we might try to get results before the
    // model is done running. Thus we record the model results for this object
    // and keep track of any callers that try to get a response too early
    // and notify them later.
    //
    // All data access is on the main queue
    var imageResults: [[String: Any]]?
    var ocrResults: [[String: Any]]?
    var screenDetectionResults: [[Double]]?
    var uxFrameConfidenceValues: [[Double]]?
    var flashForcedOnValues: [Double]?
    var resultCallbacks: [((_ response: ScanObject) -> Void)] = []
    
    override init() {
        super.init()
    }
    
    struct OcrResult {
        let bin: String
        let lastFour: String
        let expiryMonth: String?
        let expiryYear: String?
    }
    
    struct CardChallenged {
        let lastFour: String
        let bin: String?
        let expiryMonth: String?
        let expiryYear: String?
    }
    
    struct ScanObject {
        let objectFrames: [[String: Any]]
        let ocrFrames: [[String: Any]]
        let sdVectorFrames: [[Double]]
        var ocrResult: OcrResult?
    }
    
    func combineSdAndUxResults() -> [[Double]]? {
        guard let screenDetectionResults = screenDetectionResults, let uxFrameConfidenceValues = uxFrameConfidenceValues, let flashForcedOnValues = flashForcedOnValues else {
            return nil
        }
        
        guard !uxFrameConfidenceValues.isEmpty else {
            return screenDetectionResults
        }
        
        let combinedResult = zip(zip(screenDetectionResults, uxFrameConfidenceValues).map { $0.0 + $0.1 }, flashForcedOnValues).map { $0.0 + [$0.1] }
        return combinedResult
    }
    
    func toScanObject() -> ScanObject {
        return ScanObject(objectFrames: self.imageResults ?? [], ocrFrames: self.ocrResults ?? [], sdVectorFrames: combineSdAndUxResults() ?? [], ocrResult: nil)
    }
    
    override func onResultReady(imageResults: [[String: Any]], ocrResults: [[String: Any]], screenDetectionResults: [[Double]], uxFrameConfidenceValues: [[Double]], flashForcedOnValues: [Double]) {
        DispatchQueue.main.async {
            self.imageResults = imageResults
            self.ocrResults = ocrResults
            self.screenDetectionResults = screenDetectionResults
            self.uxFrameConfidenceValues = uxFrameConfidenceValues
            self.flashForcedOnValues = flashForcedOnValues
            
            for complete in self.resultCallbacks {
                complete(self.toScanObject())
            }
            
            self.resultCallbacks = []
        }
    }
    
    func result(complete: @escaping ((_ scanObject: ScanObject) -> Void)) {
        DispatchQueue.main.async {
            guard let _ = self.imageResults, let _ = self.ocrResults, let _ = self.screenDetectionResults else {
                self.resultCallbacks.append(complete)
                return
            }
            
            complete(self.toScanObject())
        }
    }
}
