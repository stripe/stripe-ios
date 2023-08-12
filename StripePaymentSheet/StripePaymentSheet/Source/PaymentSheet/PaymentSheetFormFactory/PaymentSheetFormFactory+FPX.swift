//
//  PaymentSheetFormFactory+FPX.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/12/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

extension PaymentSheetFormFactory {
    
    func makeFPX() -> PaymentMethodElement {
        let apiPath = "fpx[bank]"
        let dropdownItems: [DropdownFieldElement.DropdownItem] = STPFPXBankBrand.allCases.map {
            .init(pickerDisplayName: STPFPXBank.stringFrom($0) ?? "",
                  labelDisplayName: STPFPXBank.stringFrom($0) ?? "",
                  accessibilityValue: STPFPXBank.stringFrom($0) ?? "",
                  rawData: STPFPXBank.identifierFrom($0) ?? "")
        }
        let previousCustomerInputIndex = dropdownItems.firstIndex { item in
            item.rawData == getPreviousCustomerInput(for: apiPath)
        }
        let dropdownElement = DropdownFieldElement(
            items: dropdownItems,
            defaultIndex: previousCustomerInputIndex ?? 0,
            label: STPLocalizedString("Bank", "Select a bank dropdown for FPX"),
            theme: theme
        )
        let bankDropdown = PaymentMethodElementWrapper(dropdownElement) { dropdown, params in
            let selectedValue = dropdownElement.selectedItem.rawData
            params.paymentMethodParams.additionalAPIParameters[apiPath] = selectedValue
            return params
        }
        
        
        let contactSection: Element? = makeContactInformationSection(
            nameRequiredByPaymentMethod: false,
            emailRequiredByPaymentMethod: false,
            phoneRequiredByPaymentMethod: false
        )

        let addressSection: Element? = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
        let elements: [Element?] = [contactSection, bankDropdown, addressSection]
        return FormElement(
            autoSectioningElements: elements.compactMap { $0 },
            theme: theme
        )
    }
}
