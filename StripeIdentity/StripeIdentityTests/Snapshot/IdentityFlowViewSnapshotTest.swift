//
//  IdentityFlowViewSnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Jaime Park on 2/4/22.
//

import FBSnapshotTestCase
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
@testable import StripeIdentity


class IdentityFlowViewSnapshotTest: FBSnapshotTestCase {
    let idFlowView = IdentityFlowView()

    let headerViewModel: HeaderView.ViewModel = .init(backgroundColor: .lightGray,
                                                      headerType: .banner(iconViewModel: .none),
                                                      titleText: "Title Text")

    let contentView: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = "Here is a content view. Look at all this amazing content."
        return label
    }()

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testFlowView_HeaderView() {
        verifyView(with: .init(
            headerViewModel: headerViewModel,
            contentView:  contentView,
            buttonText: "Continue",
            didTapButton: {}
        ))
    }

    func testFlowView_NoHeaderView() {
        verifyView(with: .init(
            headerViewModel: nil,
            contentView:  contentView,
            buttonText: "Continue",
            didTapButton: {}
        ))
    }

    func testFlowView_ZeroInset() {
        verifyView(with: .init(
            headerViewModel: nil,
            contentViewModel: .init(view: contentView, inset: .zero),
            buttons: []
        ))
    }

    func testFlowView_Reconfigured() {
        let preConfigureContentView: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.text = "Uh oh. This content view should not be shown. Something went wrong."
            return label
        }()

        let postConfigureContentView: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.text = "This is the post configured content view. This view should be shown"
            return label
        }()

        // Configure once with the pre-configuration content view
        idFlowView.configure(with: .init(
            headerViewModel: nil,
            contentView:  preConfigureContentView,
            buttonText: "Continue",
            didTapButton: {}
        ))

        // Verify view with reconfigured content view
        verifyView(with: .init(
            headerViewModel: headerViewModel,
            contentViewModel: .init(view: postConfigureContentView, inset: nil),
            buttons: [])
        )
    }

    func verifyView(
        with viewModel: IdentityFlowView.ViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 350, height: 400))
        idFlowView.configure(with: viewModel)
        view.addAndPinSubview(idFlowView)
        FBSnapshotVerifyView(view, file: file, line: line)
    }
}
