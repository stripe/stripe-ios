//
//  STPiDEALBankPickerInputFieldSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Mel Ludowise on 2/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

final class STPiDEALBankPickerInputFieldSnapshotTests: FBSnapshotTestCase {

    private var field: STPiDEALBankPickerInputField!

    override func setUp() {
        super.setUp()
        //        recordMode = true

        field = STPiDEALBankPickerInputField()
        field.sizeToFit()
        field.frame.size.width = 200
    }

    func testEmptySelection() {
        FBSnapshotVerifyView(field)
    }

    func testWithSelection() {
        // Select knab
        guard let index = BankDataSource.banks.firstIndex(of: .knab) else {
            return XCTFail("Expected to find `.knab` in BankDataSource")
        }

        // Explicitly select a row
        field.pickerView.selectRow(index, inComponent: 0, animated: false)

        // Because we're calling this programitacally, we need to explicitly
        // call didSelectRow
        field.pickerView.delegate?.pickerView?(
            field.pickerView, didSelectRow: index, inComponent: 0)

        FBSnapshotVerifyView(field)
    }
}
