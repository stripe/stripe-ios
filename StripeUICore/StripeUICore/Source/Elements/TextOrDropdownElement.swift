//
//  TextOrDropdownElement.swift
//  StripeUICore
//
//  Created by Nick Porter on 9/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// Describes an element that is either a text or dropdown element
@_spi(STP) public protocol TextOrDropdownElement: Element {

    /// The raw data for the element, e.g. the text of a textfield or raw data of a dropdown item
    var rawData: String { get }

    /// Sets the raw data for this element
    func setRawData(_ rawData: String, shouldAutoAdvance: Bool)
}

extension TextOrDropdownElement {
    public func setRawData(_ rawData: String) {
        setRawData(rawData, shouldAutoAdvance: true)
    }
}

// MARK: Conformance

extension TextFieldElement: TextOrDropdownElement {
    public var rawData: String {
        return text
    }

    public func setRawData(_ rawData: String, shouldAutoAdvance: Bool = true) {
        // Intentional, ignore shouldAutoAdvance as setting the text does not cause an automatic advance like DropdownFieldElement
        setText(rawData)
    }

}

extension DropdownFieldElement: TextOrDropdownElement {
    public var rawData: String {
        return items[selectedIndex].rawData
    }

    public func setRawData(_ rawData: String, shouldAutoAdvance: Bool = true) {
        guard let itemIndex = items.firstIndex(where: {$0.rawData.lowercased() == rawData.lowercased()
            || $0.pickerDisplayName.string.lowercased() == rawData.lowercased()}) else {
                return
            }

        select(index: itemIndex, shouldAutoAdvance: shouldAutoAdvance)
    }
}
