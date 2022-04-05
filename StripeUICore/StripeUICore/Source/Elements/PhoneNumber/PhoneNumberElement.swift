//
//  PhoneNumberElement.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 9/22/21.
//

import UIKit

@_spi(STP) import StripeCore

@_spi(STP) public class PhoneNumberElement: Element {
    
    public lazy var view: UIView = {
        let elementView = PhoneNumberFieldView(
            regionDropDown: regionElement.view,
            regionPrefixLabel: regionPrefixLabel,
            numberTextView: numberElement.view
        )
        let view = FloatingPlaceholderView(contentView: elementView)
        view.placeholder = STPLocalizedString("Mobile number", "Form field header for entering a mobile phone number")
        return view
    }()
    
    public var delegate: ElementDelegate? = nil
    
    private(set) lazy var regionElement: DropdownFieldElement = {
        let element = DropdownFieldElement(items: sortedPickerValues,
                                           defaultIndex: 0,
                                           label: nil,
                                           didUpdate: { [weak self] _ in
                                            guard let self = self else {
                                                return
                                            }
                                            let metadata = self.sortedRegionInfo[self.regionElement.selectedIndex].metadata
                                            self.regionPrefixLabel.text = metadata?.prefix
                                            self.numberElement.configuration = TextFieldElement.Address.PhoneNumberConfiguration(regionCode: self.selectedRegionCode)
                                            self.delegate?.didUpdate(element: self)
                                           })
        element.delegate = self
        return element
    }()
    
    private lazy var numberElement: TextFieldElement = {
        let numberElement = TextFieldElement(configuration: TextFieldElement.Address.PhoneNumberConfiguration(regionCode: sortedRegionInfo[0].regionCode))
        numberElement.delegate = self
        numberElement.shouldInsetContent = false
        return numberElement
    }()
    
    private let locale: Locale
    
    public var phoneNumber: PhoneNumber? {
        return PhoneNumber(number: numberElement.text, countryCode: selectedRegionCode)
    }
    
    public func resetNumber() {
        numberElement.resetText()
    }
    
    /// Phone number text formatted as E164 or unformatted if unknown region
    public var phoneNumberText: String? {
        if let phoneNumber = phoneNumber {
            let e164Formatted =  phoneNumber.string(as: .e164)
            if e164Formatted == phoneNumber.prefix || e164Formatted.isEmpty {
                return nil // user hasn't entered anything
            } else {
                return phoneNumber.string(as: .e164)
            }
        } else if case .valid = numberElement.validationState {
            return numberElement.text
        }
        return nil
    }
    
    public init(locale: Locale = Locale.autoupdatingCurrent) {
        self.locale = locale
    }
    
    var selectedRegionCode: String? {
        return sortedRegionInfo[regionElement.selectedIndex].regionCode
    }
    
    
    var selectedMetadata: PhoneNumber.Metadata? {
        return sortedRegionInfo[regionElement.selectedIndex].metadata
    }
    
    private lazy var regionPrefixLabel: UILabel = {
        let label = UILabel()
        label.font = ElementsUITheme.current.fonts.subheadline
        label.textColor = ElementsUITheme.current.colors.placeholderText
        label.text = selectedMetadata?.prefix
        return label
    }()
    
    // MARK: - Sorted Picker Values
    private(set) lazy var sortedRegionInfo: [RegionInfo] = {
        
        var allRegionInfo: [RegionInfo] = locale.sortedByTheirLocalizedNames(PhoneNumber.Metadata.allMetadata,
                                                                             thisRegionFirst: true).map { metadata in
            let regionCode = metadata.regionCode
            let flagEmoji = String.countryFlagEmoji(for: regionCode)
            
            let identifier = Locale.identifier(fromComponents: [
                NSLocale.Key.countryCode.rawValue: regionCode
            ])
            let name: String = locale.localizedString(forRegionCode: regionCode) ?? regionCode
                        
            return RegionInfo(flagEmoji: flagEmoji, name: name, labelName: flagEmoji ?? regionCode, metadata: metadata)
        }

        allRegionInfo.append(RegionInfo(flagEmoji: "🌐", name: String.Localized.other, labelName: "🌐", metadata: nil))
        
        return allRegionInfo
    }()
    
    private lazy var sortedPickerValues: [DropdownFieldElement.DropdownItem] = {
                
        return sortedRegionInfo.map { regionInfo in
            let pickerDisplayName: String = {
                if let flagEmoji = regionInfo.flagEmoji {
                    return [flagEmoji, regionInfo.name].joined(separator: " ")
                } else {
                    return regionInfo.name
                }
            }()
            return DropdownFieldElement.DropdownItem(pickerDisplayName: pickerDisplayName,
                                                     labelDisplayName: regionInfo.labelName,
                                                     accessibilityLabel: regionInfo.name)
        }
    }()
}

// MARK: - ElementDelegate
/// :nodoc:
extension PhoneNumberElement: ElementDelegate {
    public func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }
    
    public func didFinishEditing(element: Element) {
        if element as? DropdownFieldElement == regionElement {
            _ = numberElement.becomeResponder()
        } else {
            delegate?.didFinishEditing(element: self)
        }
    }
    
    
}

// MARK: - Data Helpers
/// :nodoc:
extension PhoneNumberElement {
    struct RegionInfo {
        let flagEmoji: String?
        let name: String
        let labelName: String
        let metadata: PhoneNumber.Metadata?
        
        var regionCode: String? {
            return metadata?.regionCode
        }
    }
}

