//
//  PaymentMethodTypeCollectionViewCellSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Till Hellmund on 11/21/24.
//

import Foundation
import StripeCoreTestUtils
import UIKit

@testable@_spi(STP) import StripePaymentSheet

class PaymentMethodTypeCollectionViewCellSnapshotTests: STPSnapshotTestCase {
    
    func test_withPromoBadge() {
        let cell = PaymentMethodTypeCollectionView.PaymentTypeCell()
        cell.paymentMethodType = .instantDebits
        cell.promoBadgeText = "$5"
        verify(cell)
    }
    
    func test_withPromoBadge_customAppearance() {
        var appearance = PaymentSheet.Appearance()
        appearance.cornerRadius = 2
        appearance.primaryButton.successTextColor = .black
        appearance.primaryButton.successBackgroundColor = .red
        
        let cell = PaymentMethodTypeCollectionView.PaymentTypeCell()
        cell.paymentMethodType = .instantDebits
        cell.appearance = appearance
        cell.promoBadgeText = "$5"
        verify(cell)
    }
    
    func verify(
        _ cell: UICollectionViewCell,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = CellWrapperView(
            cell: cell,
            size: CGSize(width: 120, height: PaymentMethodTypeCollectionView.cellHeight)
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
