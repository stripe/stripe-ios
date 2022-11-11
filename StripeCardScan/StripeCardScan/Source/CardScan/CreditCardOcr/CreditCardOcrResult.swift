//
//  CreditCardOcrResult.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/20/20.
//  Copyright © 2020 Sam King. All rights reserved.
//

import Foundation

class CreditCardOcrResult: MachineLearningResult {
    let mostRecentPrediction: CreditCardOcrPrediction
    let number: String
    let expiry: String?
    let name: String?
    let state: MainLoopState

    // this is only used by Card Verify and the Liveness check and filled in by the UxModel
    var hasCenteredCard: CenteredCardState?

    init(
        mostRecentPrediction: CreditCardOcrPrediction,
        number: String,
        expiry: String?,
        name: String?,
        state: MainLoopState,
        duration: Double,
        frames: Int
    ) {
        self.mostRecentPrediction = mostRecentPrediction
        self.number = number
        self.expiry = expiry
        self.name = name
        self.state = state
        super.init(duration: duration, frames: frames)
    }

    var expiryMonth: String? {
        return expiry.flatMap { $0.split(separator: "/").first.map { String($0) } }
    }
    var expiryYear: String? {
        return expiry.flatMap { $0.split(separator: "/").last.map { String($0) } }
    }

    static func finishedWithNonNumberSideCard(
        prediction: CreditCardOcrPrediction,
        duration: Double,
        frames: Int
    ) -> CreditCardOcrResult {
        let result = CreditCardOcrResult(
            mostRecentPrediction: prediction,
            number: "",
            expiry: nil,
            name: nil,
            state: .finished,
            duration: duration,
            frames: frames
        )
        result.hasCenteredCard = .nonNumberSide
        return result
    }
}
