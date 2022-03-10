//
//  PaymentTypeCellSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 12/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

class PaymentTypeCellSnapshotTests: FBSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
//        recordMode = true
    }
    
    func testCardUnselected() {
        let cell = PaymentMethodTypeCollectionView.PaymentTypeCell()
        cell.paymentMethodType = .card
        cell.frame = CGRect(origin: .zero, size: CGSize(width: PaymentMethodTypeCollectionView.cellHeight, height: PaymentMethodTypeCollectionView.cellHeight))
        FBSnapshotVerifyView(cell)
    }
    
    func testCardSelected() {
        let cell = PaymentMethodTypeCollectionView.PaymentTypeCell()
        cell.paymentMethodType = .card
        cell.frame = CGRect(origin: .zero, size: CGSize(width: PaymentMethodTypeCollectionView.cellHeight, height: PaymentMethodTypeCollectionView.cellHeight))
        cell.isSelected = true
        FBSnapshotVerifyView(cell)
    }
    
    @available(iOS 13.0, *)
    func testCardUnselected_forceDarkMode() {
        let cell = PaymentMethodTypeCollectionView.PaymentTypeCell()
        cell.overrideUserInterfaceStyle = .dark
        cell.paymentMethodType = .card
        cell.frame = CGRect(origin: .zero, size: CGSize(width: PaymentMethodTypeCollectionView.cellHeight, height: PaymentMethodTypeCollectionView.cellHeight))
        FBSnapshotVerifyView(cell)
    }
    
    @available(iOS 13.0, *)
    func testCardSelected_forceDarkMode() {
        let cell = PaymentMethodTypeCollectionView.PaymentTypeCell()
        cell.overrideUserInterfaceStyle = .dark
        cell.paymentMethodType = .card
        cell.frame = CGRect(origin: .zero, size: CGSize(width: PaymentMethodTypeCollectionView.cellHeight, height: PaymentMethodTypeCollectionView.cellHeight))
        cell.isSelected = true
        FBSnapshotVerifyView(cell)
    }
}
