//
//  STPCountryPickerInputField.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 11/16/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import UIKit

@_spi(STP) public class STPCountryPickerInputField: STPGenericInputPickerField {

    var countryPickerDataSource: CountryPickerDataSource {
        wrappedDataSource.inputDataSource as! CountryPickerDataSource
    }

    class CountryCodeValidator: STPInputTextFieldValidator {
        override public var inputValue: String? {
            didSet {
                validationState =
                    inputValue?.count == 2 ? .valid(message: nil) : .incomplete(description: nil)
            }
        }
    }

    override var wantsAutoFocus: Bool {
        return false
    }

    convenience init() {
        self.init(dataSource: CountryPickerDataSource(), validator: CountryCodeValidator())
    }

    func select(countryCode: String) {
        if let row = countryPickerDataSource.row(for: countryCode) {
            select(row: row)
        }
    }

    func select(row: Int) {
        pickerView.selectRow(row, inComponent: 0, animated: false)
        updateValue()
    }

    override func setupSubviews() {
        super.setupSubviews()
        // Default selection to the current country
        pickerView.selectRow(0, inComponent: 0, animated: false)
        // Set initial value
        updateValue()
    }
}

/// :nodoc:
extension STPCountryPickerInputField {
    @_spi(STP) public class CountryPickerDataSource: NSObject, STPGenericInputPickerFieldDataSource
    {

        @_spi(STP) public let countries: [(code: String, displayName: String)] = {

            let currentCountryCode = Locale.autoupdatingCurrent.stp_regionCode
            let locale = NSLocale.autoupdatingCurrent

            let unsorted = Locale.stp_isoRegionCodes.compactMap { (code) -> (String, String)? in
                let identifier = Locale.identifier(fromComponents: [
                    NSLocale.Key.countryCode.rawValue: code
                ])
                if let countryName = (locale as NSLocale).displayName(
                    forKey: .identifier,
                    value: identifier
                ) {
                    return (code, countryName)
                } else {
                    return nil
                }
            }

            return unsorted.sorted { (a, b) -> Bool in
                let code1 = a.0
                let code2 = b.0

                if code1 == currentCountryCode {
                    return true
                } else if code2 == currentCountryCode {
                    return false
                } else {
                    let name1 = a.1
                    let name2 = b.1
                    return name1.compare(name2) == .orderedAscending ? true : false
                }
            }
        }()

        func row(for countryCode: String) -> Int? {
            return countries.firstIndex { (code: String, _) in
                code == countryCode
            }
        }

        @_spi(STP) public func inputPickerField(
            _ pickerField: STPGenericInputPickerField,
            titleForRow row: Int
        )
            -> String?
        {
            guard row >= 0,
                row < countries.count
            else {
                return nil
            }

            return countries[row].displayName
        }

        @_spi(STP) public func inputPickerField(
            _ pickerField: STPGenericInputPickerField,
            inputValueForRow row: Int
        )
            -> String?
        {
            guard row >= 0,
                row < countries.count
            else {
                return nil
            }

            return countries[row].code
        }

        @_spi(STP) public func numberOfRows() -> Int {
            return countries.count
        }
    }
}
