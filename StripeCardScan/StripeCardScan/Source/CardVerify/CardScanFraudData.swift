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

class CardScanFraudData: ScanEvents {
    let mutexQueue = DispatchQueue(label: "Completion loop mutex queue")

    var last4: String?
    var hasModelBeenCalled = false
    var framesWithCards: [ScannedCardImageData] = []
    var framesWithCardsAndOcr: [ScannedCardImageData] = []
    var ocrOnlyFrames: [ScannedCardImageData] = []
    var framesWithFlashCardsAndOcr: [ScannedCardImageData] = []
    var framesWithFlashAndCards: [ScannedCardImageData] = []
    var framesWithFlashAndOcr: [ScannedCardImageData] = []
    let kMaxScans = 5
    let kMaxFlashScans = 3
    var requireOcrBeforeCapturingUxOnlyFrames = true
    
    var debugRetainImages = false
    // Note: Only access these arrays on the main loop
    var savedSquareImages: [CGImage]?
    var savedFullImages: [CGImage]?
    var savedNumberBoxes: [[CGRect]]?
    
    init() { }
    
    func onFrameDetected(imageData: ScannedCardImageData, centeredCardState: CenteredCardState?, flashForcedOn: Bool) {
        mutexQueue.async {
            if self.hasModelBeenCalled {
                return
            }
            
            let hasCard = centeredCardState?.hasCard() ?? false
            
            let ocrFrameCount = self.framesWithCardsAndOcr.count + self.ocrOnlyFrames.count

            if hasCard && (ocrFrameCount > 0 || !self.requireOcrBeforeCapturingUxOnlyFrames) {
                if flashForcedOn {
                    self.framesWithFlashAndCards.append(imageData)
                } else {
                    self.framesWithCards.append(imageData)
                }
            }
            
            self.balanceFrames()
        }
    }
    
    func onNumberRecognized(number: String, expiry: Expiry?, imageData: ScannedCardImageData, centeredCardState: CenteredCardState?, flashForcedOn: Bool) {
        mutexQueue.async {
            if self.hasModelBeenCalled {
                return
            }
            
            let hasCard = centeredCardState?.hasCard() ?? false
            let scannedLastFour = String(number.suffix(4))

            /**
             This method is used to put the frame data in it's appropriate list given the `flashForcedOn` and `hasCard` flag,
             This method should be called on when we know that we want to keep the frame.
             */
            func appendFrameData(flashForcedOn: Bool, hasCard: Bool) {
                if flashForcedOn {
                    if hasCard {
                        self.framesWithFlashCardsAndOcr.append(imageData)
                    } else {
                        self.framesWithFlashAndOcr.append(imageData)
                    }
                } else if hasCard {
                    self.framesWithCardsAndOcr.append(imageData)
                } else {
                    self.ocrOnlyFrames.append(imageData)
                }
            }

            // Check if we have a card set to be challenged
            if let challengedLast4 = self.last4  {
                guard challengedLast4 == scannedLastFour else {
                    // The set card to be challenged doesn't match the scanned card.
                    // Don't use this frame at all.
                    return
                }

                // Given that the challenged card matches the frame's pan + last, put frame in appropriate list
                appendFrameData(flashForcedOn: flashForcedOn, hasCard: hasCard)

            } else {
                // If we don't have a card set to be challenged just add frameData
                appendFrameData(flashForcedOn: flashForcedOn, hasCard: hasCard)
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
    
    func onResultReady(scannedCardImagesData: [ScannedCardImageData]) {
        // TODO: Run verification pipeline and report back
    }
    
    func getCompletionLoopFrames() -> [ScannedCardImageData] {
        let completionLoopFrames = self.framesWithFlashAndOcr + self.framesWithFlashAndCards + self.framesWithFlashCardsAndOcr + self.ocrOnlyFrames + self.framesWithCards + self.framesWithCardsAndOcr
        return Array(completionLoopFrames.suffix(kMaxScans + kMaxFlashScans))
    }
    
    func onScanComplete(scanStats: ScanStats) {        
        mutexQueue.async {
            if self.hasModelBeenCalled {
                return
            }
            self.hasModelBeenCalled = true

            let completionLoopFrames = self.getCompletionLoopFrames()
            self.onResultReady(scannedCardImagesData: completionLoopFrames)
        }
    }
}
