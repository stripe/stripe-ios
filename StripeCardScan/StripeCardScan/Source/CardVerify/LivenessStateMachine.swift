/**
 Implementation of our Liveness check state machine.
 
 For more details, see this [google doc](https://docs.google.com/presentation/d/1BTfvJ1lP_hc_McqXlWvWTKpn8sg9r0yHgNMpkIJswfE/edit#slide=id.g8946cb18dd_0_38)
 
 Note: For our use of the UX model we don't distinguish between number and non number side of the
 card. We simply use it to detect if there _is_ a card and rely on OCR to tell us if it is number side.
 
 Given this uise of the UX Model, we'll scan in the `cardOnly` state for a bit longer then either
 of the OCR states to give the OCR model enough time to work.
 */
class LivenessStateMachine: OcrMainLoopStateMachine {
    var consecutiveFramesWithCard = 0
    let numberOfConsecutiveFramesWithCardStateChange = 3
    let cardOnlyStateDurationSeconds = 3.0
    let ocrAndCardStateDurationSeconds = 2.0
    let ocrOnlyStateDurationSeconds = 2.0
    
    override func transition(prediction: CreditCardOcrPrediction) -> MainLoopState? {
        let frameHasOcr = prediction.number != nil
        let frameHasCard = prediction.centeredCardState?.hasCard() ?? false
        let secondsInState = -startTimeForCurrentState.timeIntervalSinceNow
        
        if frameHasCard {
            consecutiveFramesWithCard += 1
        } else {
            consecutiveFramesWithCard = 0
        }
        
        switch (state, secondsInState, consecutiveFramesWithCard, frameHasOcr, frameHasCard) {
        case (.initial, _, numberOfConsecutiveFramesWithCardStateChange..., false, _):
            // consecutive frames with a card
            return .cardOnly
        case (.initial, _, _, true, true):
            // successful OCR and the frame has a card
            return .ocrAndCard
        case (.initial, _, _, true, false):
            // successful OCR, no card in the frame
            return .ocrOnly
        case (.cardOnly, cardOnlyStateDurationSeconds..., _, _, _):
            return .finished
        case (.cardOnly, _, _, true, _):
            // if we're cardonly and we get a frame with OCR
            return .ocrAndCard
        case (.ocrAndCard, ocrAndCardStateDurationSeconds..., _, _, _):
            return .finished
        case (.ocrOnly, ocrOnlyStateDurationSeconds..., _, _, _):
            return .finished
        case (.ocrOnly, _, _, _, true):
            // get a frame with a card when we're OCR only
            return .ocrAndCard
        default:
            return nil
        }
        
    }
    
    override func reset() -> MainLoopStateMachine {
        return LivenessStateMachine()
    }
}
