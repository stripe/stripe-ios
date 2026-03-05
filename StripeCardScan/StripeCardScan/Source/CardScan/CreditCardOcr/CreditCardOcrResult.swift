//
//  CreditCardOcrResult.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/20/20.
//  Copyright © 2020 Sam King. All rights reserved.
//

import Foundation

class CreditCardOcrResult: MachineLearningResult {
    let number: String
    let expiry: String?
    let name: String?
    let state: MainLoopState

    init(
        number: String,
        expiry: String?,
        name: String?,
        state: MainLoopState,
        duration: Double,
        frames: Int
    ) {
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
        duration: Double,
        frames: Int
    ) -> CreditCardOcrResult {
        return CreditCardOcrResult(
            number: "",
            expiry: nil,
            name: nil,
            state: .finished,
            duration: duration,
            frames: frames
        )
    }
}
