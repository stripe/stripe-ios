//
//  STPCountryPickerInputField.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 11/16/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPCountryPickerInputField: STPInputTextField {
    
    class CountryCodeValidator: STPInputTextFieldValidator {
        override public var inputValue: String? {
            didSet {
                validationState = inputValue?.count == 2 ? .valid(message: nil) : .incomplete(description: nil)
            }
        }
    }
    
    let countryDataSource = CountryPickerDataSource()
    let pickerView = UIPickerView()
    
    override var wantsAutoFocus: Bool {
        return false
    }
    
    convenience init() {
        self.init(formatter: STPInputTextFieldFormatter(), validator: CountryCodeValidator())
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        pickerView.delegate = self
        pickerView.dataSource = countryDataSource
        inputView = pickerView
        
        rightView = UIImageView(image: STPImageLibrary.safeImageNamed("chevronDown"))
        rightViewMode = .always
        
        pickerView.selectRow(0, inComponent: 0, animated: false)
        // manually call delegate method
        pickerView(pickerView, didSelectRow: 0, inComponent: 0)
    }
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        // hide the caret
        return .zero
    }
    
    override public func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
    }
}

/// :nodoc:
extension STPCountryPickerInputField: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        guard let string = countryDataSource.displayName(at: row) else {
            return nil
        }
        // Make sure the picker font matches our standard input font
        return NSAttributedString(string: string, attributes: [.font: font ?? UIFont.preferredFont(forTextStyle: .body)])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        text = countryDataSource.displayName(at: row)
        validator.inputValue = countryDataSource.countryCode(at: row)
    }
}

/// :nodoc:
extension STPCountryPickerInputField {
    class CountryPickerDataSource: NSObject, UIPickerViewDataSource {
        
        let countries: [(code: String, displayName: String)] = {
            
            let currentCountryCode = Locale.autoupdatingCurrent.regionCode
            let locale = NSLocale.autoupdatingCurrent
            
            
            let unsorted = Locale.isoRegionCodes.compactMap { (code) -> (String, String)? in
                let identifier = Locale.identifier(fromComponents: [
                  NSLocale.Key.countryCode.rawValue: code
                ])
                if let countryName = (locale as NSLocale).displayName(forKey: .identifier, value: identifier) {
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
        
        func displayName(at index: Int) -> String? {
            guard index >= 0,
                  index < countries.count else {
                return nil
            }
            
            return countries[index].displayName
        }
        
        func countryCode(at index: Int) -> String?  {
            guard index >= 0,
                  index < countries.count else {
                return nil
            }
            
            return countries[index].code
        }
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return countries.count
        }
    }
}
