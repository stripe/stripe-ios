/**
 This is our completion loop buffer.
 
 In general, our goal is to capture frames that will work best with our fraud models while capturing fraud behavior. As such:
  1. We give top priority to frames where the UX model finds a card _and_ we perform OCR on the frame successfully
  2. Next priority goes to frames that the UX model finds a card but it could _not_ perform OCR on the frame
  3. Lowest priority goes to frames that pass OCR but _not_ the UX model
 
 One consequence of this priority is that even if we perform OCR successfully we could end up with all frames _without_
 OCR because we give priority to UX.
 
 We can assume that any frames that pass OCR will be recent (within the last 2-3 seconds). This is _always_ true for
 OCR, but for UX we might get a few older frames because our logic for starting non number side card scans requires a few
 consecutive frames where the UX model detects a card.
 
 # Correctness

 This interface is thread safe, but all shared state access needs to happen in the `mutexQueue`. The mutexQueue
 enforces ordering constraints and will process frames in the correct order as defined by the `ScanEvents` calling
 sequence.
 
 */

import CoreGraphics
import UIKit

public class CardScanFraudData: ScanEvents {
    let mutexQueue = DispatchQueue(label: "Completion loop mutex queue")
    var hasModelBeenCalled = false
    var framesWithCards: [FrameData] = []
    var framesWithCardsAndOcr: [FrameData] = []
    var ocrOnlyFrames: [FrameData] = []
    var framesWithFlashCardsAndOcr: [FrameData] = []
    var framesWithFlashAndCards: [FrameData] = []
    var framesWithFlashAndOcr: [FrameData] = []
    let kMaxScans = 5
    let kMaxFlashScans = 3
    var requireOcrBeforeCapturingUxOnlyFrames = true
    
    public var debugRetainImages = false
    // Note: Only access these arrays on the main loop
    public var savedSquareImages: [CGImage]?
    public var savedFullImages: [CGImage]?
    public var savedNumberBoxes: [[CGRect]]?
    
    public init() { }
    
    public func onFrameDetected(croppedCardSize: CGSize, squareCardImage: CGImage, fullCardImage: CGImage, centeredCardState: CenteredCardState?, uxFrameConfidenceValues: UxFrameConfidenceValues?, flashForcedOn: Bool) {
        mutexQueue.async {
            if self.hasModelBeenCalled {
                return
            }
            
            let hasCard = centeredCardState?.hasCard() ?? false
            
            let ocrFrameCount = self.framesWithCardsAndOcr.count + self.ocrOnlyFrames.count
            
            // only start collecting UX samples after OCR starts
            let frameData = FrameData(bin: nil, last4: nil, expiry: nil, numberBoundingBox: nil, numberBoxesInFullImageFrame: nil, croppedCardSize: croppedCardSize, squareCardImage: squareCardImage, fullCardImage: fullCardImage, centeredCardState: centeredCardState, ocrSuccess: false, uxFrameConfidenceValues: uxFrameConfidenceValues, flashForcedOn: flashForcedOn)
            
            if hasCard && (ocrFrameCount > 0 || !self.requireOcrBeforeCapturingUxOnlyFrames) {
                if flashForcedOn {
                    self.framesWithFlashAndCards.append(frameData)
                } else {
                    self.framesWithCards.append(frameData)
                }
            }
            
            self.balanceFrames()
        }
    }
    
    public func onNumberRecognized(number: String, expiry: Expiry?, numberBoundingBox: CGRect, expiryBoundingBox: CGRect?, croppedCardSize: CGSize, squareCardImage: CGImage, fullCardImage: CGImage, centeredCardState: CenteredCardState?, uxFrameConfidenceValues: UxFrameConfidenceValues?, flashForcedOn: Bool, numberBoxesInFullImageFrame: [CGRect]) {
        mutexQueue.async {
            if self.hasModelBeenCalled {
                return
            }
            
            let hasCard = centeredCardState?.hasCard() ?? false
            let frameData = FrameData(bin: String(number.prefix(6)), last4: String(number.suffix(4)), expiry: expiry, numberBoundingBox: numberBoundingBox, numberBoxesInFullImageFrame: numberBoxesInFullImageFrame, croppedCardSize: croppedCardSize, squareCardImage: squareCardImage, fullCardImage: fullCardImage, centeredCardState: centeredCardState, ocrSuccess: true, uxFrameConfidenceValues: uxFrameConfidenceValues, flashForcedOn: flashForcedOn)
            
            if flashForcedOn && hasCard {
                self.framesWithFlashCardsAndOcr.append(frameData)
            } else if flashForcedOn {
                self.framesWithFlashAndOcr.append(frameData)
            } else if hasCard {
                self.framesWithCardsAndOcr.append(frameData)
            } else {
                self.ocrOnlyFrames.append(frameData)
            }
            
            self.balanceFrames()
        }
    }
    
    private func balanceFrames() {
        self.framesWithCardsAndOcr = Array(self.framesWithCardsAndOcr.suffix(kMaxScans))
        
        // make sure that we have a total of kMaxScans across OCR+UX, UX, and OCR frames giving priority to OCR+UX
        let framesWithCardsToHold = [kMaxScans - self.framesWithCardsAndOcr.count, 0].max() ?? kMaxScans
        self.framesWithCards = Array(self.framesWithCards.suffix(framesWithCardsToHold))
        
        let ocrFramesToHold = [kMaxScans - self.framesWithCardsAndOcr.count - self.framesWithCards.count, 0].max() ?? kMaxScans
        self.ocrOnlyFrames = Array(self.ocrOnlyFrames.suffix(ocrFramesToHold))
        
        // separately, keep kMaxFlashScans number of frames with the flash on
        self.framesWithFlashCardsAndOcr = Array(self.framesWithFlashCardsAndOcr.suffix(kMaxFlashScans))
        
        let framesWithFlashCardsToHold = [kMaxFlashScans - self.framesWithFlashCardsAndOcr.count, 0].max() ?? kMaxFlashScans
        self.framesWithFlashAndCards = Array(self.framesWithFlashAndCards.suffix(framesWithFlashCardsToHold))
        
        let ocrFlashFramesToHold = [kMaxFlashScans - self.framesWithFlashCardsAndOcr.count - self.framesWithFlashAndCards.count, 0].max() ?? kMaxFlashScans
        self.framesWithFlashAndOcr = Array(self.framesWithFlashAndOcr.suffix(ocrFlashFramesToHold))
    }
    
    func onResultReady(imageResults: [[String: Any]], ocrResults: [[String: Any]], screenDetectionResults: [[Double]], uxFrameConfidenceValues: [[Double]], flashForcedOnValues: [Double]) {
        // TODO: Run verification pipeline and report back
    }
    
    func getCompletionLoopFrames() -> [FrameData] {
        let completionLoopFrames = self.framesWithFlashAndOcr + self.framesWithFlashAndCards + self.framesWithFlashCardsAndOcr + self.ocrOnlyFrames + self.framesWithCards + self.framesWithCardsAndOcr
        return Array(completionLoopFrames.suffix(kMaxScans + kMaxFlashScans))
    }
    
    public func onScanComplete(scanStats: ScanStats) {
        
        guard #available(iOS 11.2, *) else {
            return
        }
        
        mutexQueue.async {
            if self.hasModelBeenCalled {
                return
            }
            self.hasModelBeenCalled = true
            
            // NOTE(kingst): we will want this code when we implement the CardVerifyIntent
            // completion loop, so I'll just comment it out for now to avoid compiler warnings
            /*
            let completionLoopFrames = self.getCompletionLoopFrames()
            
            // run the model on each of our RecognizedData items
            let images  = completionLoopFrames.map { $0.squareCardImage }
            let fullCardImages = completionLoopFrames.map { $0.fullCardImage }
            let numberBoxes = completionLoopFrames.map { $0.numberBoxesInFullImageFrame ?? [] }
            let ocrFrames = self.ocrOnlyFrames + self.framesWithCards.filter { $0.ocrSuccess } + self.framesWithCardsAndOcr
            let ocrFrameResults = ocrFrames.map { $0.toDictForOcrFrame() }
            let uxFrameConfidenceValues = completionLoopFrames.compactMap { $0.uxFrameConfidenceValues?.toArray() }
            let flashForcedOnValues = completionLoopFrames.compactMap { $0.flashForcedOn ? 1.0 : 0.0 }

            self.framesWithCardsAndOcr = []
            self.framesWithCards = []
            self.ocrOnlyFrames = []
            
            if self.debugRetainImages {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.savedFullImages = fullCardImages
                    self.savedSquareImages = images
                    self.savedNumberBoxes = numberBoxes
                }
            }
             */
            
            // TODO: this is where we'd start the CardVerifyIntent verification protocol
            //
            // After the protocol finishes we need to call
            /// self.onResultReady(imageResults: objectDetectionResults,
            ///               ocrResults: ocrFrameResults,
            ///               screenDetectionResults: screenDetectionFrames,
            ///               uxFrameConfidenceValues: uxFrameConfidenceValues,
            ///               flashForcedOnValues: flashForcedOnValues)
        }
    }
}
