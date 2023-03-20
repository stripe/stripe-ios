//
//  StrictModeFramesTest.swift
//  StripeCardScanTests
//
//  Created by Jaime Park on 3/10/22.
//

import XCTest
@testable @_spi(STP) import StripeCardScan

class StrictFramesTests: XCTestCase {
    let correctCardNumber = ScannedCardDetails(number: "0000111122223333")
    let incorrectCardNumber = ScannedCardDetails(number: "7777888899990000")

    /// Test to check that `visibleMatchingCardCount` increments properly
    func testVisibleMatchingCardCount() {
        let cardVerifyStateMachine = CardVerifyStateMachine(requiredLastFour: correctCardNumber.last4)
        /// First frame detected is a mismatch frame with a card present
        transition(stateMachine: cardVerifyStateMachine, prediction: mismatchNumberPrediction(cardVisible: true))
        XCTAssertEqual(cardVerifyStateMachine.visibleMatchingCardCount, 0)

        /// Simulate transitioning state machine with 9 matching frames
        var totalMatchedFramesWithCard = 9
        repeat {
            transition(stateMachine: cardVerifyStateMachine, prediction: matchNumberPrediction(cardVisible: true))
            totalMatchedFramesWithCard -= 1
        } while (totalMatchedFramesWithCard > 0)

        XCTAssertEqual(cardVerifyStateMachine.visibleMatchingCardCount, 9)

        /// Simulate transitioning to a mismatching frame. Visible card count should not change.
        transition(stateMachine: cardVerifyStateMachine, prediction: mismatchNumberPrediction(cardVisible: true))
        XCTAssertEqual(cardVerifyStateMachine.visibleMatchingCardCount, 9)
    }

    func testCardVerifyStateMachine_NotStrict_Success() {
        let cardVerifyStateMachine = CardVerifyStateMachine(requiredLastFour: correctCardNumber.last4)

        /**
         Mock that:
         1. We are currently in the `ocrAndCard` state
         2. We have been in the `ocrAndCard` state for 1.5 seconds (the exact timeout limit)
         3. We have already accounted for 1 frames that have matching pan & detected a card
         */
        cardVerifyStateMachine.state = .ocrAndCard
        cardVerifyStateMachine.startTimeForCurrentState = Date().addingTimeInterval(-1.5)
        cardVerifyStateMachine.visibleMatchingCardCount = 1

        /// Run through 1 more frame with matching pan & card detected fulfilling the strictModeFrame amount (0)
        transition(stateMachine: cardVerifyStateMachine, prediction: matchNumberPrediction(cardVisible: true))

        XCTAssertEqual(cardVerifyStateMachine.visibleMatchingCardCount, 2)
        XCTAssertEqual(cardVerifyStateMachine.state, .finished)
    }

    func testCardVerifyStateMachine_Strict_Success() {
        /// Configure the Bouncer session with strict mode frames
        let cardVerifyStateMachine = CardVerifyStateMachine(
            requiredLastFour: correctCardNumber.last4,
            strictModeFramesCount: .high
        )

        /**
         Mock that:
         1. We are currently in the `ocrAndCard` state
         2. We have been in the `ocrAndCard` state for 3 seconds (well passed the timeout limit)
         3. We have already accounted for 4 frames that have matching pan & detected a card
         */
        cardVerifyStateMachine.state = .ocrAndCard
        cardVerifyStateMachine.startTimeForCurrentState = Date().addingTimeInterval(-3)
        cardVerifyStateMachine.visibleMatchingCardCount = 4

        /// Run through 1 more frame with matching pan & card detected fulfilling the strictModeFrame amount (5)
        transition(stateMachine: cardVerifyStateMachine, prediction: matchNumberPrediction(cardVisible: true))

        XCTAssertEqual(cardVerifyStateMachine.visibleMatchingCardCount, 5)
        XCTAssertEqual(cardVerifyStateMachine.state, .finished)
    }

    func testCardVerifyStateMachine_Reset() {
        /// Configure the Bouncer session with strict mode frames
        let cardVerifyStateMachine = CardVerifyStateMachine(
            requiredLastFour: correctCardNumber.last4,
            strictModeFramesCount: .high
        )

        /**
         Mock that:
         1. We are currently in the `ocrAndCard` state
         2. We have been in the `ocrAndCard` state for 3 seconds (well passed the timeout limit)
         3. We have only found 1 matching frame; Not enough to pass strict mode
         */
        cardVerifyStateMachine.state = .ocrAndCard
        cardVerifyStateMachine.startTimeForCurrentState = Date().addingTimeInterval(-3)
        cardVerifyStateMachine.visibleMatchingCardCount = 1

        /// Run through 1 more frame with matching pan to trigger reset to initial state
        transition(stateMachine: cardVerifyStateMachine, prediction: matchNumberPrediction(cardVisible: true))
        XCTAssertEqual(cardVerifyStateMachine.state, .initial)
        XCTAssertEqual(cardVerifyStateMachine.visibleMatchingCardCount, 0)

    }
}

extension StrictFramesTests {
    func transition(stateMachine: CardVerifyStateMachine, prediction: CreditCardOcrPrediction) {
        let _ = stateMachine.event(prediction: prediction)
    }

    func mismatchNumberPrediction(cardVisible: Bool) -> CreditCardOcrPrediction {
        return generateOcrPrediction(withNumber: incorrectCardNumber.number, withCenteredCardState: cardVisible ? .numberSide : .noCard)
    }

    func matchNumberPrediction(cardVisible: Bool) -> CreditCardOcrPrediction {
        return generateOcrPrediction(withNumber: correctCardNumber.number, withCenteredCardState: cardVisible ? .numberSide : .noCard)
    }

    func generateOcrPrediction(
        withNumber number: String,
        withCenteredCardState centeredCardState: CenteredCardState
    ) -> CreditCardOcrPrediction {
        return CreditCardOcrPrediction(
            image: ImageHelpers.createBlankCGImage(),
            ocrCroppingRectangle: CGRect(),
            number: number,
            expiryMonth: nil,
            expiryYear: nil,
            name: nil,
            computationTime: 0.0,
            numberBoxes: nil,
            expiryBoxes: nil,
            nameBoxes: nil,
            centeredCardState: centeredCardState
        )
    }
}
