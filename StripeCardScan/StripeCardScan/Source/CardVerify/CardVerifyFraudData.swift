import Foundation

class CardVerifyFraudData: CardScanFraudData {
    // one subtlety we have is that we might try to get results before the
    // model is done running. Thus we record the model results for this object
    // and keep track of any callers that try to get a response too early
    // and notify them later.
    //
    // All data access is on the main queue
    var verificationFrameDataResults: [VerificationFramesData]?
    var resultCallbacks: [((_ response: [VerificationFramesData]) -> Void)] = []

    static let maxCompletionLoopFrames = 5
    
    override init() {
        super.init()
    }

    init(last4: String?) {
        super.init()
        self.last4 = last4
    }

    override func onResultReady(scannedCardImagesData: [ScannedCardImageData]) {
        DispatchQueue.main.async {
            let verificationFramesData = scannedCardImagesData.compactMap { $0.toVerificationFramesData() }
            self.verificationFrameDataResults = verificationFramesData

            for complete in self.resultCallbacks {
                complete(verificationFramesData)
            }

            self.resultCallbacks = []
        }
    }
    
    func result(complete: @escaping ([VerificationFramesData]) -> Void ) {
        DispatchQueue.main.async {
            guard let results = self.verificationFrameDataResults else {
                self.resultCallbacks.append(complete)
                return
            }

            complete(results)
        }
    }
}
