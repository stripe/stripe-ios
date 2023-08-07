class UxAndOcrMainLoop: OcrMainLoop {
    init(
        stateMachine: MainLoopStateMachine
    ) {
        super.init(analyzers: [])

        errorCorrection = ErrorCorrection(stateMachine: stateMachine)

        let ssdOcr = SSDCreditCardOcr(dispatchQueueLabel: "Ux+Ocr queue")
        let appleOcr = AppleCreditCardOcr(dispatchQueueLabel: "apple queue")

        let ocrImplementations = [
            UxAnalyzer(asyncWith: ssdOcr), UxAnalyzer(asyncWith: appleOcr),
        ]
        setupMl(ocrImplementations: ocrImplementations)
    }
}
