//
//  AnimatedBorderViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/19/22.
//

import Foundation
import FBSnapshotTestCase
@testable import StripeIdentity

final class AnimatedBorderViewSnapshotTest: FBSnapshotTestCase {

    let view: AnimatedBorderView = {
        let view = AnimatedBorderView()
        view.frame.size = CGSize(width: 300, height: 200)
        return view
    }()

    override func setUp() {
        super.setUp()

//        recordMode = true
    }

    func testGradientThickBorder() {
        verifyView(with: .init(
            color1: IdentityUI.stripeBlurple,
            color2: .white,
            borderWidth: 4,
            cornerRadius: 12,
            isAnimating: false
        ))
    }

    func testGradientThinBorder() {
        verifyView(with: .init(
            color1: IdentityUI.stripeBlurple,
            color2: .white,
            borderWidth: 1,
            cornerRadius: 4,
            isAnimating: false
        ))
    }

    func testNoGradient() {
        verifyView(with: .init(
            color1: .white,
            color2: .white,
            borderWidth: 4,
            cornerRadius: 12,
            isAnimating: false
        ))
    }
}

private extension AnimatedBorderViewSnapshotTest {
    func verifyView(
        with viewModel: AnimatedBorderView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.configure(with: viewModel)
        FBSnapshotVerifyView(view, file: file, line: line)
    }
}
