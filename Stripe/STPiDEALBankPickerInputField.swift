//
//  STPiDEALBankPickerInputField.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 2/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

final class STPiDEALBankPickerInputField: STPGenericInputPickerField {

    init() {
        super.init(dataSource: BankDataSource())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(formatter: STPInputTextFieldFormatter, validator: STPInputTextFieldValidator) {
        super.init(formatter: formatter, validator: validator)
    }

    override func setupSubviews() {
        super.setupSubviews()

        placeholder = STPLocalizedString("Select bank", "label for iDEAL-bank selection picker")
    }
}

// MARK: - BankDataSource
final class BankDataSource: STPGenericInputPickerFieldDataSource {
    // Since displayName is localized, banks should be sorted dynamically to
    // ensure they always display alphabetically for the current language.
    static let banks: [STPiDEALBank] = STPiDEALBank.allCases.sorted(by: {
        $0.displayName < $1.displayName
    })

    func bank(at index: Int) -> STPiDEALBank? {
        guard index >= 0 && index < BankDataSource.banks.count else {
            return nil
        }
        return BankDataSource.banks[index]
    }

    func numberOfRows() -> Int {
        return BankDataSource.banks.count
    }

    func inputPickerField(_ pickerField: STPGenericInputPickerField, titleForRow row: Int)
        -> String?
    {
        return bank(at: row)?.displayName
    }

    func inputPickerField(_ pickerField: STPGenericInputPickerField, inputValueForRow row: Int)
        -> String?
    {
        return bank(at: row)?.name
    }
}
