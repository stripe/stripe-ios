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

    var acceptedImageConfigs: CardImageVerificationAcceptedImageConfigs?

    static let maxCompletionLoopFrames = 5

    init(last4: String? = nil, acceptedImageConfigs: CardImageVerificationAcceptedImageConfigs? = nil) {
        super.init()
        self.last4 = last4
        self.acceptedImageConfigs = acceptedImageConfigs
    }

    override func onResultReady(scannedCardImagesData: [ScannedCardImageData]) {
        DispatchQueue.main.async {
            let imageCompressionTask = TrackableTask()
            let processedVerificationFrames = scannedCardImagesData.compactMap { $0.toVerificationFramesData(imageConfig: self.acceptedImageConfigs) }
            imageCompressionTask.trackResult(processedVerificationFrames.count > 0 ? .success : .failure)

            let verificationFramesData = processedVerificationFrames.compactMap { $0.0 }
            /// Use the image metadata from the most recent frame
            let verificationImageMetadata = processedVerificationFrames.compactMap { $0.1 }.last

            /// Calculate the compressed and b64 encoded image sizes in bytes
            let totalImagePayloadSizeInBytes = verificationFramesData.compactMap{ $0.imageData }.reduce(0) { $0 + $1.count }

            /// Log the verification payload info + image compression duration
            ScanAnalyticsManager.shared.trackImageCompressionDuration(task: imageCompressionTask)
            ScanAnalyticsManager.shared.logPayloadInfo(with: .init(
                imageCompressionType: verificationImageMetadata?.compressionType.rawValue ?? "unknown",
                imageCompressionQuality: verificationImageMetadata?.compressionQuality ?? 0.0,
                imagePayloadSize: totalImagePayloadSizeInBytes)
            )

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
