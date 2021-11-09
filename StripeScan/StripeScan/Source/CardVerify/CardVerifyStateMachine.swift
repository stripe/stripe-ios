//
//  CardVerifyStateMachine.swift
//  CardVerify
//
//  Created by Adam Wushensky on 8/7/20.
//

@available(iOS 11.2, *)
@objc public class CardVerifyStateMachine: OcrMainLoopStateMachine {
    var requiredLastFour: String?
    var requiredBin: String?
    
    let ocrAndCardStateDurationSeconds = 1.5
    let ocrOnlyStateDurationSeconds = 1.5
    let ocrDelayForCardStateDurationSeconds = 2.0
    let ocrIncorrectDurationSeconds = 2.0
    let ocrForceFlashDurationSeconds = 1.5
    
    public init(requiredLastFour: String? = nil, requiredBin: String? = nil) {
        self.requiredLastFour = requiredLastFour
        self.requiredBin = requiredBin
    }
    
    override public func transition(prediction: CreditCardOcrPrediction) -> MainLoopState? {
        let frameHasOcr = prediction.number != nil
        let frameOcrMatchesRequiredLastFour = requiredLastFour == nil || String(prediction.number?.suffix(4) ?? "") == requiredLastFour
        let frameOcrMatchesRequiredBin = requiredBin == nil || String(prediction.number?.prefix(6) ?? "") == requiredBin
        let frameOcrMatchesRequired = frameOcrMatchesRequiredBin && frameOcrMatchesRequiredLastFour
        let frameHasCard = prediction.centeredCardState?.hasCard() ?? false
        let secondsInState = -startTimeForCurrentState.timeIntervalSinceNow
        
        switch (self.state, secondsInState, frameHasOcr, frameHasCard, frameOcrMatchesRequired) {
        case (.initial, _, true, true, true):
            // successful OCR and card
            return .ocrAndCard
        case (.initial, _, true, _, false):
            // saw an incorrect card
            return .ocrIncorrect
        case (.initial, _, _, true, _):
            // got a frame with a card
            return .cardOnly
        case (.initial, _, true, _, true):
            // successful OCR and the card matches required
            return .ocrOnly
        case (.cardOnly, _, true, _, false):
            // if we're cardOnly and we get a frame with OCR and it does not match the required card
            return .ocrIncorrect
        case (.cardOnly, _, true, _, true):
            // if we're cardonly and we get a frame with OCR and it matches the required card
            return .ocrAndCard
        case (.ocrOnly, _, _, true, _):
            // if we're ocrOnly and we get a card
            return .ocrAndCard
        case (.ocrOnly, self.ocrOnlyStateDurationSeconds..., _, _, _):
            // ocrOnly times out without getting a card
            return .ocrDelayForCard
        case (.ocrAndCard, self.ocrAndCardStateDurationSeconds..., _, _, _):
            return Bouncer.useFlashFlow ? .ocrForceFlash : .finished
        case (.ocrIncorrect, _, true, false, true):
            // if we're ocrIncorrect and we get a valid pan
            return .ocrOnly
        case (.ocrIncorrect, _, true, true, true):
            // if we're ocrIncorrect and we get a valid pan and card
            return .ocrAndCard
        case (.ocrIncorrect, _, true, _, false):
            // if we're ocrIncorrect and we get another bad pan, restart the timer
            return .ocrIncorrect
        case (.ocrIncorrect, self.ocrIncorrectDurationSeconds..., _, _, _):
            // if we're ocrIncorrect and the timer has elapsed
            return .initial
        case (.ocrDelayForCard, _, _, true, _):
            // if we're ocrDelayForCard and we get a card
            return .ocrAndCard
        case (.ocrDelayForCard, self.ocrDelayForCardStateDurationSeconds..., _, _, _):
            // if we're ocrDelayForCard and we time out
            return Bouncer.useFlashFlow ? .ocrForceFlash : .finished
        case (.ocrForceFlash, self.ocrForceFlashDurationSeconds..., _, _, _):
            return .finished
        default:
            return nil
        }
    }
    
    override public func reset() -> MainLoopStateMachine {
        return CardVerifyStateMachine(requiredLastFour: requiredLastFour, requiredBin: requiredBin)
    }
}

@available(iOS 13.0, *)
@objc public class CardVerifyAccurateStateMachine: OcrMainLoopStateMachine {
    var requiredLastFour: String?
    var requiredBin: String?
    var hasNamePrediction = false
    var hasExpiryPrediction = false
    
    let ocrAndCardStateDurationSeconds = 1.5
    let ocrOnlyStateDurationSeconds = 1.5
    let ocrDelayForCardStateDurationSeconds = 2.0
    let ocrIncorrectDurationSeconds = 2.0
    let ocrForceFlashDurationSeconds = 1.5
    var nameExpiryDurationSeconds = 4.0
    
    public init(requiredLastFour: String? = nil, requiredBin: String? = nil, maxNameExpiryDurationSeconds: Double ) {
        self.requiredLastFour = requiredLastFour
        self.requiredBin = requiredBin
        self.nameExpiryDurationSeconds = maxNameExpiryDurationSeconds
    }
 
    override public func transition(prediction: CreditCardOcrPrediction) -> MainLoopState? {
        hasExpiryPrediction = hasExpiryPrediction || prediction.expiryForDisplay != nil
        hasNamePrediction = hasNamePrediction || prediction.name != nil
        
        let frameHasOcr = prediction.number != nil
        let frameOcrMatchesRequiredLastFour = requiredLastFour == nil || String(prediction.number?.suffix(4) ?? "") == requiredLastFour
        let frameOcrMatchesRequiredBin = requiredBin == nil || String(prediction.number?.prefix(6) ?? "") == requiredBin
        let frameOcrMatchesRequired = frameOcrMatchesRequiredBin && frameOcrMatchesRequiredLastFour
        let frameHasCard = prediction.centeredCardState?.hasCard() ?? false
        let hasNameAndExpiry = hasNamePrediction && hasExpiryPrediction
        let secondsInState = -startTimeForCurrentState.timeIntervalSinceNow
        
        switch (self.state, secondsInState, frameHasOcr, frameHasCard, frameOcrMatchesRequired, hasNameAndExpiry) {
        // MARK: Initial State
        case (.initial, _, true, true, true, _):
            // successful OCR and card
            return .ocrAndCard
        case (.initial, _, true, _, false, _):
            // saw an incorrect card
            return .ocrIncorrect
        case (.initial, _, _, true, _, _):
            // got a frame with a card
            return .cardOnly
        case (.initial, _, true, _, true, _):
            // successful OCR and the card matches required
            return .ocrOnly
         
        // MARK: Card Only State
        case (.cardOnly, _, true, _, false, _):
            // if we're cardOnly and we get a frame with OCR and it does not match the required card
            return .ocrIncorrect
        case (.cardOnly, _, true, _, true, _):
            // if we're cardonly and we get a frame with OCR and it matches the required card
            return .ocrAndCard
        
        // MARK: Ocr Only State
        case (.ocrOnly, _, _, true, _, _):
            // if we're ocrOnly and we get a card
            return .ocrAndCard
        case (.ocrOnly, self.ocrOnlyStateDurationSeconds..., _, _, _, _):
            // ocrOnly times out without getting a card
            return .ocrDelayForCard
        
        // MARK: Ocr Incorrect State
        case (.ocrIncorrect, _, true, false, true, _):
            // if we're ocrIncorrect and we get a valid pan
            return .ocrOnly
        case (.ocrIncorrect, _, true, true, true, _):
            // if we're ocrIncorrect and we get a valid pan and card
            return .ocrAndCard
        case (.ocrIncorrect, _, true, _, false, _):
            // if we're ocrIncorrect and we get another bad pan, restart the timer
            return .ocrIncorrect
        case (.ocrIncorrect, self.ocrIncorrectDurationSeconds..., _, _, _, _):
            // if we're ocrIncorrect and the timer has elapsed
            return .initial

        // MARK: Ocr and Card State
        case (.ocrAndCard, self.ocrAndCardStateDurationSeconds..., _, _, _, false):
            // if we're in ocr&card and dont have name&expiry
            return .nameAndExpiry
        case (.ocrAndCard, self.ocrAndCardStateDurationSeconds..., _, _, _, true):
            // if we're in ocr&card and we have name&expiry
            return Bouncer.useFlashFlow ? .ocrForceFlash : .finished

        // MARK: Ocr Delay For Card State
        case (.ocrDelayForCard, self.ocrDelayForCardStateDurationSeconds..., _, _, _, false):
            // if we're ocrDelayForCard, we time out, and we dont have name&expiry
            return .nameAndExpiry
        case (.ocrDelayForCard, self.ocrDelayForCardStateDurationSeconds..., _, _, _, true):
            // if we're ocrDelayForCard, we time out but we have name&expiry
            return Bouncer.useFlashFlow ? .ocrForceFlash : .finished
        case (.ocrDelayForCard, _, _, true, _, _):
            // if we're ocrDelayForCard and we get a card
            return .ocrAndCard
        
        // MARK: Name And Expiry State
        case (.nameAndExpiry, self.nameExpiryDurationSeconds..., _, _, _, _):
            // if we're checking for name&expiry and we time out
            return Bouncer.useFlashFlow ? .ocrForceFlash : .finished
        case (.nameAndExpiry, _, _, _, _, true):
            // if we're checking for name&expiry and we find name&expiry
            return Bouncer.useFlashFlow ? .ocrForceFlash : .finished
                  
        // MARK: Ocr Force Flash State
        case (.ocrForceFlash, self.ocrForceFlashDurationSeconds..., _, _, _, _):
            return .finished
        default:
            return nil
        }
    }
    
    override public func reset() -> MainLoopStateMachine {
        return CardVerifyAccurateStateMachine(requiredLastFour: requiredLastFour, requiredBin: requiredBin, maxNameExpiryDurationSeconds: nameExpiryDurationSeconds)
    }
}
