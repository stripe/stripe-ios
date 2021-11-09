//
//  MainLoopStateMachine.swift
//  CardScan
//
//  Created by Sam King on 8/5/20.
//

import Foundation

public enum MainLoopState {
    case initial
    case ocrOnly
    case cardOnly
    case ocrAndCard
    case ocrIncorrect
    case ocrDelayForCard
    case ocrForceFlash
    case finished
    case nameAndExpiry
}

public protocol MainLoopStateMachine {
    func loopState() -> MainLoopState
    func event(prediction: CreditCardOcrPrediction) -> MainLoopState
    func reset() -> MainLoopStateMachine
}

// Note: This class is _not_ thread safe, it relies on syncrhonization
// from the `OcrMainLoop`
@objc open class OcrMainLoopStateMachine: NSObject, MainLoopStateMachine {
    public var state: MainLoopState = .initial
    public var startTimeForCurrentState = Date()
    public let errorCorrectionDurationSeconds = 2.0
    
    public override init() {}
    
    public func loopState() -> MainLoopState {
        return state
    }
    
    public func event(prediction: CreditCardOcrPrediction) -> MainLoopState {
        let newState = transition(prediction: prediction)
        if let newState = newState {
            startTimeForCurrentState = Date()
            state = newState
        }
        
        return newState ?? state
    }
    
    open func transition(prediction: CreditCardOcrPrediction) -> MainLoopState? {
        let timeInCurrentStateSeconds = -startTimeForCurrentState.timeIntervalSinceNow
        let frameHasOcr = prediction.number != nil
        
        switch (state, timeInCurrentStateSeconds, frameHasOcr) {
        case (.initial, _, true):
            return .ocrOnly
        case (.ocrOnly, errorCorrectionDurationSeconds..., _):
            return .finished
        default:
            // no state transitions
            return nil
        }
    }
    
    open func reset() -> MainLoopStateMachine {
        return OcrMainLoopStateMachine()
    }
}

@objc public class OcrAccurateMainLoopStateMachine: NSObject, MainLoopStateMachine {
    var state: MainLoopState = .initial
    var startTimeForCurrentState = Date()
    var hasExpiryPrediction = false
    
    let minimumErrorCorrection = 2.0
    var maximumErrorCorrection = 4.0
    
    public func loopState() -> MainLoopState {
        return state
    }
    
    override init() { }
    
    public init(maxErrorCorrection: Double) {
        self.maximumErrorCorrection = maxErrorCorrection
    }
    
    public func event(prediction: CreditCardOcrPrediction) -> MainLoopState {
        let newState = transition(prediction: prediction)
        if let newState = newState {
            startTimeForCurrentState = Date()
            state = newState
        }
        return newState ?? state
    }
    
    public func transition(prediction: CreditCardOcrPrediction) -> MainLoopState? {
        let timeInCurrentStateSeconds = -startTimeForCurrentState.timeIntervalSinceNow
        let frameHasOcr = prediction.number != nil
        hasExpiryPrediction = hasExpiryPrediction || prediction.expiryForDisplay != nil
        switch (state, timeInCurrentStateSeconds, frameHasOcr, hasExpiryPrediction) {
        case (.initial, _, true, _):
            return .ocrOnly
        case (.ocrOnly, minimumErrorCorrection..., _, true):
            return .finished
        case (.ocrOnly, maximumErrorCorrection..., _, false):
            return .finished
        default:
            // no state transitions
            return nil
        }
    }
    public func reset() -> MainLoopStateMachine {
        return OcrAccurateMainLoopStateMachine(maxErrorCorrection: maximumErrorCorrection)
    }
}
