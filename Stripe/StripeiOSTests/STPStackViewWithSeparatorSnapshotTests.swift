//
//  STPStackViewWithSeparatorSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
@_spi(STP) import StripeUICore

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPStackViewWithSeparatorSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func embedInRenderableView(_ stackView: StackViewWithSeparator) -> UIView {
        let containingView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 400))
        containingView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: containingView.leadingAnchor),
            containingView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: containingView.topAnchor),
            containingView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
        ])
        containingView.frame.size = containingView.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize
        )
        return containingView
    }

    func testHorizontal() {
        let label1 = UILabel()
        label1.text = "Label 1"
        let label2 = UILabel()
        label2.text = "Label 2"
        let label3 = UILabel()
        label3.text = "Label 3"
        let stackView = StackViewWithSeparator(arrangedSubviews: [label1, label2, label3])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        stackView.separatorColor = .lightGray

        STPSnapshotVerifyView(embedInRenderableView(stackView))
    }

    func testVertical() {
        let label1 = UILabel()
        label1.text = "Label 1"
        let label2 = UILabel()
        label2.text = "Label 2"
        let label3 = UILabel()
        label3.text = "Label 3"
        let stackView = StackViewWithSeparator(arrangedSubviews: [label1, label2, label3])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        stackView.separatorColor = .lightGray

        STPSnapshotVerifyView(embedInRenderableView(stackView))
    }

    func testSingleArrangedSubviewHorizontal() {
        let label1 = UILabel()
        label1.text = "Label 1"
        let stackView = StackViewWithSeparator(arrangedSubviews: [label1])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        stackView.separatorColor = .lightGray

        STPSnapshotVerifyView(embedInRenderableView(stackView))
    }

    func testSingleArrangedSubviewVertical() {
        let label1 = UILabel()
        label1.text = "Label 1"
        let stackView = StackViewWithSeparator(arrangedSubviews: [label1])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        stackView.separatorColor = .lightGray

        STPSnapshotVerifyView(embedInRenderableView(stackView))
    }

    func testCustomColorHorizontal() {
        let label1 = UILabel()
        label1.text = "Label 1"
        let label2 = UILabel()
        label2.text = "Label 2"
        let label3 = UILabel()
        label3.text = "Label 3"
        let stackView = StackViewWithSeparator(arrangedSubviews: [label1, label2, label3])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        stackView.separatorColor = .red

        STPSnapshotVerifyView(embedInRenderableView(stackView))
    }

    func testCustomColorVertical() {
        let label1 = UILabel()
        label1.text = "Label 1"
        let label2 = UILabel()
        label2.text = "Label 2"
        let label3 = UILabel()
        label3.text = "Label 3"
        let stackView = StackViewWithSeparator(arrangedSubviews: [label1, label2, label3])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        stackView.separatorColor = .red

        STPSnapshotVerifyView(embedInRenderableView(stackView))
    }

    func testDisabledColor() {
        let label1 = UILabel()
        label1.text = "Label 1"
        let label2 = UILabel()
        label2.text = "Label 2"
        let label3 = UILabel()
        label3.text = "Label 3"
        let stackView = StackViewWithSeparator(arrangedSubviews: [label1, label2, label3])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        stackView.separatorColor = .lightGray
        stackView.drawBorder = true
        stackView.isUserInteractionEnabled = false

        STPSnapshotVerifyView(embedInRenderableView(stackView))
    }

    func testCustomBackgroundColor() {
        let label1 = UILabel()
        label1.text = "Label 1"
        let label2 = UILabel()
        label2.text = "Label 2"
        let label3 = UILabel()
        label3.text = "Label 3"
        let stackView = StackViewWithSeparator(arrangedSubviews: [label1, label2, label3])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        stackView.separatorColor = .lightGray
        stackView.drawBorder = true
        stackView.customBackgroundColor = .green

        STPSnapshotVerifyView(embedInRenderableView(stackView))
    }

    func testCustomDisabledColor() {
        let label1 = UILabel()
        label1.text = "Label 1"
        let label2 = UILabel()
        label2.text = "Label 2"
        let label3 = UILabel()
        label3.text = "Label 3"
        let stackView = StackViewWithSeparator(arrangedSubviews: [label1, label2, label3])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        stackView.separatorColor = .lightGray
        stackView.customBackgroundDisabledColor = .green
        stackView.drawBorder = true
        stackView.isUserInteractionEnabled = false

        STPSnapshotVerifyView(embedInRenderableView(stackView))
    }

    func testPartialSeparatorHorizontal() {
        let label1 = UILabel()
        label1.text = "Label 1"
        let label2 = UILabel()
        label2.text = "Label 2"
        let label3 = UILabel()
        label3.text = "Label 3"
        let stackView = StackViewWithSeparator(arrangedSubviews: [label1, label2, label3])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        stackView.separatorColor = .lightGray
        stackView.separatorStyle = .partial

        STPSnapshotVerifyView(embedInRenderableView(stackView))
    }

    func testPartialSeparatorVertical() {
        let label1 = UILabel()
        label1.text = "Label 1"
        let label2 = UILabel()
        label2.text = "Label 2"
        let label3 = UILabel()
        label3.text = "Label 3"
        let stackView = StackViewWithSeparator(arrangedSubviews: [label1, label2, label3])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        stackView.separatorColor = .lightGray
        stackView.separatorStyle = .partial

        STPSnapshotVerifyView(embedInRenderableView(stackView))
    }

}
