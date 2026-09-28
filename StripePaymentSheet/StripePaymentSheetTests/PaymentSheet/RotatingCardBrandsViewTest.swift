//
//  RotatingCardBrandsViewTest.swift
//  StripePaymentSheetTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import XCTest

@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@_spi(STP) import StripePaymentsUI

@MainActor
class RotatingCardBrandsViewTest: XCTestCase {
    func testBrandsShrinkDuringPendingRotation() {
        // Given a pending rotation to the second rotating brand
        let view = RotatingCardBrandsView()
        view.cardBrands = [.visa, .mastercard, .amex, .discover, .dinersClub, .JCB]
        let animation = DeferredAnimator()
        view.rotateCardBrand(animation: animation)

        // When only one rotating brand remains
        view.cardBrands = [.visa, .mastercard, .amex, .discover]
        view.stopAnimating()

        // Then the animation uses the current list and keeps the remaining brand visible
        animation.finish()
        XCTAssertFalse(view.isAnimating)
        XCTAssertFalse(view.rotatingCardBrandView.isHidden)
        XCTAssertEqual(view.rotatingIndex, 0)
        XCTAssertEqual(view.rotatingCardBrandView.image, STPImageLibrary.cardBrandImage(for: .discover))
    }

    func testBrandsClearedDuringPendingRotation() {
        let view = RotatingCardBrandsView()
        view.cardBrands = [.visa, .mastercard, .amex, .discover, .dinersClub]
        let animation = DeferredAnimator()
        view.rotateCardBrand(animation: animation)

        view.cardBrands = []

        animation.finish()
        XCTAssertFalse(view.isAnimating)
        XCTAssertTrue(view.rotatingCardBrandView.isHidden)
        XCTAssertNil(view.rotatingCardBrandView.image)
    }

    func testBrandsReplacedDuringPendingRotation() {
        let view = RotatingCardBrandsView()
        view.cardBrands = [.visa, .mastercard, .amex, .discover, .dinersClub]
        let animation = DeferredAnimator()
        view.rotateCardBrand(animation: animation)

        view.cardBrands = [.visa, .mastercard, .amex, .JCB, .unionPay]
        view.stopAnimating()

        animation.finish()
        XCTAssertFalse(view.isAnimating)
        XCTAssertEqual(view.rotatingIndex, 1)
        XCTAssertEqual(view.rotatingCardBrandView.image, STPImageLibrary.cardBrandImage(for: .unionPay))
    }
}

// Explicitly defer the animation block so the regression does not depend on UIKit's scheduling.
@MainActor
private class DeferredAnimator: UIViewPropertyAnimator {
    private var animations: (() -> Void)?
    private var completion: ((UIViewAnimatingPosition) -> Void)?

    override func addAnimations(_ animation: @escaping () -> Void) {
        animations = animation
    }

    override func addCompletion(_ completion: @escaping (UIViewAnimatingPosition) -> Void) {
        self.completion = completion
    }

    override func startAnimation(afterDelay delay: TimeInterval) {
        // The test decides when to execute the delayed callback.
    }

    func finish() {
        animations?()
        completion?(.end)
        animations = nil
        completion = nil
    }
}
