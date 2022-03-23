class UxAndOcrMainLoop: OcrMainLoop {
    init(stateMachine: MainLoopStateMachine) {
        super.init(analyzers: [])
        
        errorCorrection = ErrorCorrection(stateMachine: stateMachine)
        
        if #available(iOS 13.0, *) {
            let ssdOcr = SSDCreditCardOcr(dispatchQueueLabel: "Ux+Ocr queue")
            let appleOcr = AppleCreditCardOcr(dispatchQueueLabel: "apple queue")
            
            let ocrImplementations = [UxAnalyzer(with: ssdOcr), UxAnalyzer(with: appleOcr)]
            setupMl(ocrImplementations: ocrImplementations)
        } else {
            let ssdOcr0 = SSDCreditCardOcr(dispatchQueueLabel: "Ux+Ocr queue 0")
            let ssdOcr1 = SSDCreditCardOcr(dispatchQueueLabel: "Ux+Ocr queue 1")

            let ocrImplementations = [UxAnalyzer(with: ssdOcr0), UxAnalyzer(with: ssdOcr1)]
            setupMl(ocrImplementations: ocrImplementations)
        }
    }
}
