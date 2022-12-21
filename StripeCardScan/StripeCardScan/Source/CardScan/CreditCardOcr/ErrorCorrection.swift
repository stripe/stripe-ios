import Foundation

class ErrorCorrection {
    let stateMachine: MainLoopStateMachine
    var frames = 0
    var numbers: [String: Int] = [:]
    var expiries: [String: Int] = [:]
    var names: [String: Int] = [:]
    let startTime = Date()
    var mostRecentPrediction: CreditCardOcrPrediction?

    var framesPerSecond: Double {
        return Double(frames) / -startTime.timeIntervalSinceNow
    }

    init(
        stateMachine: MainLoopStateMachine
    ) {
        self.stateMachine = stateMachine
    }

    var number: String? {
        return self.numbers.sorted { $0.1 > $1.1 }.map { $0.0 }.first
    }

    func result() -> CreditCardOcrResult? {
        guard stateMachine.loopState() != .initial else { return nil }
        let predictedNumber = self.numbers.sorted { $0.1 > $1.1 }.map { $0.0 }.first
        let predictedExpiry = self.expiries.sorted { $0.1 > $1.1 }.map { $0.0 }.first
        let predictedName = self.names.sorted { $0.1 > $1.1 }.map { $0.0 }.first
        guard let prediction = self.mostRecentPrediction else { return nil }

        guard let number = predictedNumber else {
            // TODO(stk): this is a hack to deal with the case where we are finished
            // but don't have a OCR (e.g., non-number side for liveness)
            if stateMachine.loopState() == .finished {
                return CreditCardOcrResult.finishedWithNonNumberSideCard(
                    prediction: prediction,
                    duration: -startTime.timeIntervalSinceNow,
                    frames: frames
                )
            }

            if stateMachine.loopState() == .ocrIncorrect, let number = prediction.number {
                return CreditCardOcrResult(
                    mostRecentPrediction: prediction,
                    number: number,
                    expiry: prediction.expiryForDisplay,
                    name: prediction.name,
                    state: stateMachine.loopState(),
                    duration: -startTime.timeIntervalSinceNow,
                    frames: frames
                )
            }

            return nil
        }

        return CreditCardOcrResult(
            mostRecentPrediction: prediction,
            number: number,
            expiry: predictedExpiry,
            name: predictedName,
            state: stateMachine.loopState(),
            duration: -startTime.timeIntervalSinceNow,
            frames: frames
        )
    }

    func add(prediction: CreditCardOcrPrediction) -> CreditCardOcrResult? {
        self.frames += 1

        let newState = stateMachine.event(prediction: prediction)

        if newState != .ocrIncorrect {
            if let pan = prediction.number {
                self.numbers[pan] = (self.numbers[pan] ?? 0) + 1
            }
            if let expiry = prediction.expiryForDisplay {
                self.expiries[expiry] = (self.expiries[expiry] ?? 0) + 1
            }
            for name in prediction.name?.split(separator: "\n").map({ String($0) }) ?? [] {
                self.names[name] = (self.names[name] ?? 0) + 1
            }
        }

        self.mostRecentPrediction = prediction

        return result()
    }

    func reset() -> ErrorCorrection {
        return ErrorCorrection(stateMachine: stateMachine.reset())
    }
}
