/**
 This is the main loop for OCR. It runs one of our OCR systems in paralell with the Apple OCR system and
 combines results. From a high level this implements a standard producer-consumer where the main
 system will push images and ROI rectangles into the main loop and two Analyzers, or OCR systems
 will consume the images.

 The producer, which pushes images will keep N (2 currently) images in the queue and when a new image
 comes in it will remove old images leaving the N most recent images. That way we can try to get more
 diversity in images by virtue of maximizing the time in between images that it reads.

 The consumers pull images from the queue and run the full OCR algorithm, including expiry extraction and
 full error correction on the combined results.

 In terms of iOS abstractions, we make heavy use of dispatch queues. We have a single `mutexQueue`
 that we use to mutate our shared state. This queue is a serial queue and our method for synchronizing
 access. One thing to be careful with is we use `sync` in places to access our `mutexQueue`. This
 method can lead to deadlock if you aren't careful.

 # Correcness criteria
 We make heavy use of dispatch queues for paralellism, so it's important to be disciplined about how
 we access shared state

 ## Shared state
 All shared state updates need to happeon on the `mutexQueue` except for `machineLearningQueue`,
 which we set at the constructor and access it read only.

 ## Delegate invocation
 All invocations of delegate methods need to happen on the main queue, and for each prediction there
 are one or more methods that may get called in order:
 - `prediction` this happens on all predictions
 - if the scan predicts a number, then `showCardDetails` happens with the current overall predicted number, expiry, and name
 - if the scan is complete, then `complete` includes the final result

 To finalize results, we clear out the `mainLoopDelegate` after it's done

 It's important that we not update `scanStats` after complete is called or call any futher delegate functions, although
 more predictions might come through after the fact

 We also expose `shouldUsePrediction` that delegates can implement to discard a prediction, but note that the `prediction`
 method still fires even when this returns false. Note: `shouldUsePrediction` is called from the `mutexQueue` so handlers
 don't need to synchronize but they may need to handle any computation that needs to happen on the main loop appropriately.
 
 ## userCancelled
 One aspect to be careful with when someone invokes the `userCancelled` method is that there could be a race with OCR and it
 could complete OCR in parallel with this call. The net result we want is if a caller calls this method we don't subsequenty fire any of
 the `OcrMainLoopDelegate` methods and we want to make sure that `scanStats.success` is always `false` to correctly
 denote that this scan failed.
  
 To handle this correctly we:
 - use the `userDidCancel` variable here and in any of our blocks that run on the main dispatch queue. Since this call should
 come from the main dispatch queue, those calls, where we invoke the callback methods, will run after this one and we prevent firing
 their delegate methods.
 - the logic to set `scanStats.success` will come on the `muxtexQueue`, but could execute either before or after this block runs.
    - If it's before then this block will overwrite the `success` results with the unsuccessful result here. If the
    - If it runs after, there is a check and it sets `scanStats.success` iff it isn't already set
 - we use `sync` on the `muxtexQueue` to make sure that when this method returns any subsequent calls to `scanStats` are
 always `success = false`
 
 ## backgrounding
 We track when the app is in the active state and stop accepting images when it's inactive. When it becomes active we reset
 the `errorCorrection` state before re-enabling computation.
 
 This backgrounding logic is less about correctness and more about making sure that the SDK doesn't send the caller predictions
 at unexpected times by making sure that the app is active if and when it sends notifications of success.
 */

import UIKit

protocol OcrMainLoopDelegate: AnyObject {
    func complete(creditCardOcrResult: CreditCardOcrResult)
    func prediction(prediction: CreditCardOcrPrediction, imageData: ScannedCardImageData, state: MainLoopState)
    func showCardDetails(number: String?, expiry: String?, name: String?)
    func showCardDetailsWithFlash(number: String?, expiry: String?, name: String?)
    func showWrongCard(number: String?, expiry: String?, name: String?)
    func showNoCard()
    func shouldUsePrediction(errorCorrectedNumber: String?, prediction: CreditCardOcrPrediction) -> Bool
}

protocol MachineLearningLoop: AnyObject {
    func push(imageData: ScannedCardImageData)
}

class OcrMainLoop : MachineLearningLoop {
    enum AnalyzerType {
        case apple
        case ssd
    }
    
    var scanStats = ScanStats()
    
    weak var mainLoopDelegate: OcrMainLoopDelegate?
    var errorCorrection = ErrorCorrection(stateMachine: OcrMainLoopStateMachine())
    var imageQueue: [ScannedCardImageData] = []
    var imageQueueSize = 2
    var analyzerQueue: [CreditCardOcrImplementation] = []
    let mutexQueue = DispatchQueue(label: "OcrMainLoopMutex")
    var inBackground = false
    var machineLearningQueues: [DispatchQueue] = []
    var userDidCancel = false
    
    init(analyzers: [AnalyzerType] = [.ssd, .apple]) {
        var ocrImplementations: [CreditCardOcrImplementation] = []
        for analyzer in analyzers {
            let queueLabel = "\(analyzer) OCR ML"
            switch (analyzer) {
            case .ssd:
                ocrImplementations.append(SSDCreditCardOcr(dispatchQueueLabel: queueLabel))
            case .apple:
                if #available(iOS 13.0, *) {
                    ocrImplementations.append(AppleCreditCardOcr(dispatchQueueLabel: queueLabel))
                }
            }
        }
        setupMl(ocrImplementations: ocrImplementations)
    }
    
    /// Note: you must call this function in your constructor
    func setupMl(ocrImplementations: [CreditCardOcrImplementation]) {
        scanStats.model = "ssd+apple"
        for ocrImplementation in ocrImplementations {
            analyzerQueue.append(ocrImplementation)
        }
        registerAppNotifications()
    }
    
    func reset() {
        mutexQueue.async {
            self.errorCorrection = self.errorCorrection.reset()
        }
    }
    
    static func warmUp() {
        // TODO(stk): Implement this later
    }
    
    // see the Correctness Criteria note in the comments above for why this is correct
    // Make sure you call this from the main dispatch queue
    func userCancelled() {
        userDidCancel = true
        mutexQueue.sync { [weak self] in
            guard let self = self else { return }
            self.scanStats.userCanceled = userDidCancel
            if self.scanStats.success == nil {
                self.scanStats.success = false
                self.scanStats.endTime = Date()
                self.mainLoopDelegate = nil
            }
        }
    }
    
    func push(imageData: ScannedCardImageData) {
        mutexQueue.sync {
            guard !inBackground else { return }
            // only keep the latest images
            imageQueue.insert(imageData, at: 0)
            while imageQueue.count > imageQueueSize {
                let _ = imageQueue.popLast()
            }
            
            // if we have any analyzers waiting, fire them off now
            guard let ocr = analyzerQueue.popLast() else { return }
            analyzer(ocr: ocr)
        }
    }

    func postAnalyzerToQueueAndRun(ocr: CreditCardOcrImplementation) {
        mutexQueue.async { [weak self] in
            guard let self = self else { return }
            self.analyzerQueue.insert(ocr, at: 0)
            // only kick off the next analyzer if there is an image in the queue
            if self.imageQueue.count > 0 {
                guard let ocr = self.analyzerQueue.popLast() else { return }
                self.analyzer(ocr: ocr)
            }
        }
    }
    
    func analyzer(ocr: CreditCardOcrImplementation) {
        ocr.dispatchQueue.async { [weak self] in
            var scannedCardImageData: ScannedCardImageData?
            
            // grab an image and roi from the image queue. If the image queue is empty then add ourselves
            // back to the analyzer queue
            self?.mutexQueue.sync {
                guard !(self?.inBackground ?? false) else {
                    self?.analyzerQueue.insert(ocr, at: 0)
                    return
                }
                guard let imageDataFromQueue = self?.imageQueue.popLast() else {
                    self?.analyzerQueue.insert(ocr, at: 0)
                    return
                }
                scannedCardImageData = imageDataFromQueue
            }
            
            guard let imageData = scannedCardImageData else { return }
            
            // run our ML model, add ourselves back to the analyzer queue unless we have a result
            // and the result is finished
            let prediction = ocr.recognizeCard(in: imageData.previewLayerImage, roiRectangle: imageData.previewLayerViewfinderRect)
            self?.mutexQueue.async {
                guard let self = self else { return }
                self.scanStats.scans += 1
                let delegate = self.mainLoopDelegate
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    guard !self.userDidCancel else { return }
                    delegate?.prediction(prediction: prediction, imageData: imageData, state: self.errorCorrection.stateMachine.loopState())
                }
                guard let result = self.combine(prediction: prediction), result.state == .finished else {
                    self.postAnalyzerToQueueAndRun(ocr: ocr)
                    return
                }
            }
        }
    }
    
    func combine(prediction: CreditCardOcrPrediction) -> CreditCardOcrResult? {
        guard mainLoopDelegate?.shouldUsePrediction(errorCorrectedNumber: errorCorrection.number, prediction: prediction) ?? true else { return nil }
        guard let result = errorCorrection.add(prediction: prediction) else { return nil }
        let delegate = mainLoopDelegate
        if result.state == .finished && scanStats.success == nil {
            scanStats.success = true
            scanStats.endTime = Date()
            mainLoopDelegate = nil
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard !self.userDidCancel else { return }
            switch (result.state) {
            case MainLoopState.initial, MainLoopState.cardOnly:
                delegate?.showNoCard()
            case MainLoopState.ocrIncorrect:
                delegate?.showWrongCard(number: result.number, expiry: result.expiry, name: result.name)
            case MainLoopState.ocrOnly, MainLoopState.ocrAndCard, MainLoopState.ocrDelayForCard:
                delegate?.showCardDetails(number: result.number, expiry: result.expiry, name: result.name)
            case .ocrForceFlash:
                delegate?.showCardDetailsWithFlash(number: result.number, expiry: result.expiry, name: result.name)
            case MainLoopState.finished:
                delegate?.complete(creditCardOcrResult: result)
            case MainLoopState.nameAndExpiry:
                break
            }
        }
        return result
    }
    
    // MARK: -backrounding logic
    @objc func willResignActive() {
        // make sure that no new images get pushed to our image buffer
        // and we clear out the image buffer
        mutexQueue.sync {
            self.inBackground = true
            self.imageQueue = []
        }
    }
    
    @objc func didBecomeActive() {
        mutexQueue.sync {
            self.inBackground = false
            self.errorCorrection = self.errorCorrection.reset()
        }
    }
    
    func registerAppNotifications() {
        // We don't need to unregister these functions because the system will clean
        // them up for us
        NotificationCenter.default.addObserver(self, selector: #selector(self.willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
}
