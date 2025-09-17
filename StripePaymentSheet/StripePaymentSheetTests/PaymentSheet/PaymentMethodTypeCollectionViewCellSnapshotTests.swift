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

@testable@_spi(STP) import StripePaymentSheet

// @iOS26
class PaymentMethodTypeCollectionViewCellSnapshotTests: STPSnapshotTestCase {

    func test_withPromoBadge() {
        let appearance: PaymentSheet.Appearance = .default.applyingLiquidGlassIfPossible()
        let height = appearance.cornerRadius == nil ? PaymentMethodTypeCollectionView.capsuleCornerCellHeight : PaymentMethodTypeCollectionView.uniformCornerCellHeight

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

        let height = appearance.cornerRadius == nil ? PaymentMethodTypeCollectionView.capsuleCornerCellHeight : PaymentMethodTypeCollectionView.uniformCornerCellHeight

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
