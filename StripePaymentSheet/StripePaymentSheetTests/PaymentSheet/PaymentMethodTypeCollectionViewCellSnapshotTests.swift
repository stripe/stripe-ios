//
//  PaymentMethodTypeCollectionViewCellSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Till Hellmund on 11/21/24.
//

import Foundation
import StripeCoreTestUtils
@_spi(STP) import StripeUICore
import UIKit
import XCTest

@testable@_spi(STP) import StripePaymentSheet

// @iOS26
class PaymentMethodTypeCollectionViewCellSnapshotTests: STPSnapshotTestCase {

    func test_rightToLeftLayoutStartsWithFirstPaymentMethodAtLeadingEdge() {
        let delegate = PaymentMethodTypeCollectionViewTestDelegate()
        let sut = PaymentMethodTypeCollectionView(
            paymentMethodTypes: [.stripe(.card), .stripe(.cashApp), .stripe(.afterpayClearpay)],
            appearance: .default,
            incentive: nil,
            delegate: delegate
        )
        let containerView = UIView()
        containerView.addAndPinSubview(sut)
        let window = host(
            containerView,
            size: CGSize(width: 320, height: sut.intrinsicContentSize.height),
            traits: UITraitCollection(layoutDirection: .rightToLeft)
        )
        sut.reloadData()
        sut.layoutIfNeeded()

        XCTAssertEqual(sut.effectiveUserInterfaceLayoutDirection, .rightToLeft)
        STPSnapshotVerifyView(containerView)
        withExtendedLifetime(window) {}
    }

    func test_withPromoBadge() {
        let appearance: PaymentSheet.Appearance = .default.applyingLiquidGlassIfPossible()
        let height = appearance.cornerRadius == nil ? PaymentMethodTypeCollectionView.liquidGlassCornerCellHeight : PaymentMethodTypeCollectionView.defaultCornerCellHeight

        let cell = PaymentMethodTypeCollectionView.PaymentTypeCell(frame: CGRect(x: 0, y: 0, width: 120, height: height))
        cell.paymentMethodType = .instantDebits
        cell.promoBadgeText = "$5"
        cell.appearance = appearance
        verify(cell, height: height)
    }

    func test_withPromoBadge_customAppearance() {
        var appearance = PaymentSheet.Appearance()
        appearance.cornerRadius = 2
        appearance.primaryButton.successTextColor = .black
        appearance.primaryButton.successBackgroundColor = .red

        let height = appearance.cornerRadius == nil ? PaymentMethodTypeCollectionView.liquidGlassCornerCellHeight : PaymentMethodTypeCollectionView.defaultCornerCellHeight

        let cell = PaymentMethodTypeCollectionView.PaymentTypeCell(frame: CGRect(x: 0, y: 0, width: 120, height: height))
        cell.paymentMethodType = .instantDebits
        cell.appearance = appearance
        cell.promoBadgeText = "$5"
        verify(cell, height: height)
    }

    func verify(
        _ cell: UICollectionViewCell,
        height: CGFloat,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = CellWrapperView(
            cell: cell,
            size: CGSize(width: 120, height: height)
        )
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}

private final class PaymentMethodTypeCollectionViewTestDelegate: PaymentMethodTypeCollectionViewDelegate {
    func didUpdateSelection(_ paymentMethodTypeCollectionView: PaymentMethodTypeCollectionView) {}
}

private func host(
    _ view: UIView,
    size: CGSize,
    traits: UITraitCollection
) -> UIWindow {
    let rootViewController = UIViewController()
    let contentViewController = UIViewController()
    rootViewController.addChild(contentViewController)
    rootViewController.setOverrideTraitCollection(traits, forChild: contentViewController)

    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    window.rootViewController = rootViewController
    window.isHidden = false

    contentViewController.view = view
    rootViewController.view.addAndPinSubview(view)
    contentViewController.didMove(toParent: rootViewController)
    window.layoutIfNeeded()
    return window
}

private class CellWrapperView: UIView {
    init(cell: UICollectionViewCell, size: CGSize) {
        super.init(frame: CGRect(origin: .zero, size: size))
        cell.frame = self.bounds
        addSubview(cell)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
