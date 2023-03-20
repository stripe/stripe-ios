//
//  STPGenericInputPickerFieldSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Mel Ludowise on 2/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

final class STPGenericInputPickerFieldSnapshotTests: FBSnapshotTestCase {

    private var field: STPGenericInputPickerField!

    override func setUp() {
        super.setUp()
        //        recordMode = true

        field = STPGenericInputPickerField(dataSource: MockDataSource())
        field.placeholder = "Placeholder"
        field.sizeToFit()
        field.frame.size.width = 200
    }

    func testEmptySelection() {
        STPSnapshotVerifyView(field)
    }

    func testWithDefaultSelection() {
        // The 0th row should be auto-selected when tapping into the field
        field.delegate?.textFieldDidBeginEditing?(field)

        STPSnapshotVerifyView(field)
    }

    func testWithExplicitSelection() {
        let index = 5

        // Explicitly select a row
        field.pickerView.selectRow(index, inComponent: 0, animated: false)

        // Because we're interacting with the picker programatically, we need to explicitly
        // call `resignFirstResponder` to commit the changes.
        _ = field.resignFirstResponder()

        STPSnapshotVerifyView(field)
    }
}

/// Simple DataSource that displays numbers 0–9
private final class MockDataSource: STPGenericInputPickerFieldDataSource {
    func numberOfRows() -> Int {
        return 10
    }

    func inputPickerField(_ pickerField: STPGenericInputPickerField, titleForRow row: Int)
        -> String?
    {
        return "\(row)"
    }

    func inputPickerField(_ pickerField: STPGenericInputPickerField, inputValueForRow row: Int)
        -> String?
    {
        return "\(row)"
    }
}
