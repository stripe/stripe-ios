//
//  STPCountryPickerInputField.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 11/16/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPCountryPickerInputField: STPGenericInputPickerField {

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

    override func setupSubviews() {
        super.setupSubviews()
        // Default selection to the current country
        pickerView.selectRow(0, inComponent: 0, animated: false)
        // manually call delegate method
        pickerView(pickerView, didSelectRow: 0, inComponent: 0)
    }
}

/// :nodoc:
extension STPCountryPickerInputField {
    class CountryPickerDataSource: NSObject, STPGenericInputPickerFieldDataSource {

        let countries: [(code: String, displayName: String)] = {

            let currentCountryCode = Locale.autoupdatingCurrent.regionCode
            let locale = NSLocale.autoupdatingCurrent

            let unsorted = Locale.isoRegionCodes.compactMap { (code) -> (String, String)? in
                let identifier = Locale.identifier(fromComponents: [
                    NSLocale.Key.countryCode.rawValue: code
                ])
                if let countryName = (locale as NSLocale).displayName(
                    forKey: .identifier, value: identifier)
                {
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

        func inputPickerField(_ pickerField: STPGenericInputPickerField, titleForRow row: Int)
            -> String?
        {
            guard row >= 0,
                row < countries.count
            else {
                return nil
            }

            return countries[row].displayName
        }

        func inputPickerField(_ pickerField: STPGenericInputPickerField, inputValueForRow row: Int)
            -> String?
        {
            guard row >= 0,
                row < countries.count
            else {
                return nil
            }

            return countries[row].code
        }

        func numberOfRows() -> Int {
            return countries.count
        }
    }
}
