//
//  CardVerifyStateMachine.swift
//  CardVerify
//
//  Created by Adam Wushensky on 8/7/20.
//

import Foundation

typealias StrictModeFramesCount = CardImageVerificationSheet.StrictModeFrameCount

protocol CardVerifyStateMachineProtocol {
    var requiredLastFour: String? { get }
    var requiredBin: String? { get }
    var strictModeFramesCount: StrictModeFramesCount { get }
    var visibleMatchingCardCount: Int { get set }

    func resetCountAndReturnToInitialState() -> MainLoopState
    func determineFinishedState() -> MainLoopState
}

class CardVerifyStateMachine: OcrMainLoopStateMachine, CardVerifyStateMachineProtocol {
    var requiredLastFour: String?
    var requiredBin: String?
    var strictModeFramesCount: StrictModeFramesCount
    var visibleMatchingCardCount: Int = 0

    let ocrAndCardStateDurationSeconds = 1.5
    let ocrOnlyStateDurationSeconds = 1.5
    let ocrDelayForCardStateDurationSeconds = 2.0
    let ocrIncorrectDurationSeconds = 2.0
    let ocrForceFlashDurationSeconds = 1.5
    
    init(
        requiredLastFour: String? = nil,
        requiredBin: String? = nil,
        strictModeFramesCount: CardImageVerificationSheet.StrictModeFrameCount
    ) {
        self.requiredLastFour = requiredLastFour
        self.requiredBin = requiredBin
        self.strictModeFramesCount = strictModeFramesCount
    }

    convenience init(
        requiredLastFour: String? = nil,
        requiredBin: String? = nil
    ) {
        self.init(
            requiredLastFour: requiredLastFour,
            requiredBin: requiredBin,
            strictModeFramesCount: .none
        )
    }

    func resetCountAndReturnToInitialState() -> MainLoopState {
        visibleMatchingCardCount = 0
        return .initial
    }

    func determineFinishedState() -> MainLoopState {
        if Bouncer.useFlashFlow {
            return .ocrForceFlash
        }

        /// The ocr and card state timer has elapsed. If visible card count hasn't been met within the time limit, then reset the timer and try again
        return visibleMatchingCardCount >= strictModeFramesCount.totalFrameCount ? .finished : resetCountAndReturnToInitialState()
    }

    override func transition(prediction: CreditCardOcrPrediction) -> MainLoopState? {
        let frameHasOcr = prediction.number != nil
        let frameOcrMatchesRequiredLastFour = requiredLastFour == nil || String(prediction.number?.suffix(4) ?? "") == requiredLastFour
        let frameOcrMatchesRequiredBin = requiredBin == nil || String(prediction.number?.prefix(6) ?? "") == requiredBin
        let frameOcrMatchesRequired = frameOcrMatchesRequiredBin && frameOcrMatchesRequiredLastFour
        let frameHasCard = prediction.centeredCardState?.hasCard() ?? false
        let secondsInState = -startTimeForCurrentState.timeIntervalSinceNow

        if frameHasCard && frameOcrMatchesRequired {
            visibleMatchingCardCount += 1
        }

        switch (self.state, secondsInState, frameHasOcr, frameHasCard, frameOcrMatchesRequired) {
        // MARK: Initial State
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

        // MARK: Card Only State
        case (.cardOnly, _, true, _, false):
            // if we're cardOnly and we get a frame with OCR and it does not match the required card
            return .ocrIncorrect
        case (.cardOnly, _, true, _, true):
            // if we're cardonly and we get a frame with OCR and it matches the required card
            return .ocrAndCard

        // MARK: OCR Only State
        case (.ocrOnly, _, _, true, _):
            // if we're ocrOnly and we get a card
            return .ocrAndCard
        case (.ocrOnly, self.ocrOnlyStateDurationSeconds..., _, _, _):
            // ocrOnly times out without getting a card
            return .ocrDelayForCard

        // MARK: OCR and Card State
        case (.ocrAndCard, self.ocrAndCardStateDurationSeconds..., _, _, _):
            return determineFinishedState()

        // MARK: OCR Incorrect State
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
            return resetCountAndReturnToInitialState()

        // MARK: OCR Delay for Card State
        case (.ocrDelayForCard, _, _, true, _):
            // if we're ocrDelayForCard and we get a card
            return .ocrAndCard
        case (.ocrDelayForCard, self.ocrDelayForCardStateDurationSeconds..., _, _, _):
            // if we're ocrDelayForCard and we time out
            return determineFinishedState()

        // MARK: OCR Force Flash State
        case (.ocrForceFlash, self.ocrForceFlashDurationSeconds..., _, _, _):
            return .finished
        default:
            return nil
        }
    }
    
    override  func reset() -> MainLoopStateMachine {
        return CardVerifyStateMachine(
            requiredLastFour: requiredLastFour,
            requiredBin: requiredBin,
            strictModeFramesCount: strictModeFramesCount
        )
    }
}

@available(iOS 13.0, *)
class CardVerifyAccurateStateMachine: OcrMainLoopStateMachine, CardVerifyStateMachineProtocol {
    var requiredLastFour: String?
    var requiredBin: String?
    var strictModeFramesCount: StrictModeFramesCount
    var visibleMatchingCardCount: Int = 0

    var hasNamePrediction = false
    var hasExpiryPrediction = false
    
    let ocrAndCardStateDurationSeconds = 1.5
    let ocrOnlyStateDurationSeconds = 1.5
    let ocrDelayForCardStateDurationSeconds = 2.0
    let ocrIncorrectDurationSeconds = 2.0
    let ocrForceFlashDurationSeconds = 1.5
    var nameExpiryDurationSeconds = 4.0

    init(
        requiredLastFour: String? = nil,
        requiredBin: String? = nil,
        maxNameExpiryDurationSeconds: Double,
        strictModeFramesCount: StrictModeFramesCount
    ) {
        self.requiredLastFour = requiredLastFour
        self.requiredBin = requiredBin
        self.nameExpiryDurationSeconds = maxNameExpiryDurationSeconds
        self.strictModeFramesCount = strictModeFramesCount
    }

    convenience init(
        requiredLastFour: String? = nil,
        requiredBin: String? = nil,
        maxNameExpiryDurationSeconds: Double
    ) {
        self.init(
            requiredLastFour: requiredLastFour,
            requiredBin: requiredBin,
            maxNameExpiryDurationSeconds: maxNameExpiryDurationSeconds,
            strictModeFramesCount: .none
        )
    }

    func resetCountAndReturnToInitialState() -> MainLoopState {
        visibleMatchingCardCount = 0
        return .initial
    }

    func determineFinishedState() -> MainLoopState {
        if Bouncer.useFlashFlow {
            return .ocrForceFlash
        }

        /// The ocr and card state timer has elapsed. If visible card count hasn't been met within the time limit, then reset the timer and try again
        return visibleMatchingCardCount >= strictModeFramesCount.totalFrameCount ? .finished : resetCountAndReturnToInitialState()
    }

    override func transition(prediction: CreditCardOcrPrediction) -> MainLoopState? {
        hasExpiryPrediction = hasExpiryPrediction || prediction.expiryForDisplay != nil
        hasNamePrediction = hasNamePrediction || prediction.name != nil
        
        let frameHasOcr = prediction.number != nil
        let frameOcrMatchesRequiredLastFour = requiredLastFour == nil || String(prediction.number?.suffix(4) ?? "") == requiredLastFour
        let frameOcrMatchesRequiredBin = requiredBin == nil || String(prediction.number?.prefix(6) ?? "") == requiredBin
        let frameOcrMatchesRequired = frameOcrMatchesRequiredBin && frameOcrMatchesRequiredLastFour
        let frameHasCard = prediction.centeredCardState?.hasCard() ?? false
        let hasNameAndExpiry = hasNamePrediction && hasExpiryPrediction
        let secondsInState = -startTimeForCurrentState.timeIntervalSinceNow

        if frameHasCard && frameOcrMatchesRequired {
            visibleMatchingCardCount += 1
        }

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
            return determineFinishedState()

        // MARK: Ocr Delay For Card State
        case (.ocrDelayForCard, self.ocrDelayForCardStateDurationSeconds..., _, _, _, false):
            // if we're ocrDelayForCard, we time out, and we dont have name&expiry
            return .nameAndExpiry
        case (.ocrDelayForCard, self.ocrDelayForCardStateDurationSeconds..., _, _, _, true):
            // if we're ocrDelayForCard, we time out but we have name&expiry
            return determineFinishedState()
        case (.ocrDelayForCard, _, _, true, _, _):
            // if we're ocrDelayForCard and we get a card
            return .ocrAndCard
        
        // MARK: Name And Expiry State
        case (.nameAndExpiry, self.nameExpiryDurationSeconds..., _, _, _, _):
            // if we're checking for name&expiry and we time out
            return Bouncer.useFlashFlow ? .ocrForceFlash : .finished
        case (.nameAndExpiry, _, _, _, _, true):
            // if we're checking for name&expiry and we find name&expiry
            return determineFinishedState()
                  
        // MARK: Ocr Force Flash State
        case (.ocrForceFlash, self.ocrForceFlashDurationSeconds..., _, _, _, _):
            return .finished
        default:
            return nil
        }
    }
    
    override  func reset() -> MainLoopStateMachine {
        return CardVerifyAccurateStateMachine(
            requiredLastFour: requiredLastFour,
            requiredBin: requiredBin,
            maxNameExpiryDurationSeconds: nameExpiryDurationSeconds,
            strictModeFramesCount: strictModeFramesCount
        )
    }
}
