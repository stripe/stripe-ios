//
//  TextFieldElement+USBankAccount.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/20/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension TextFieldElement {
    struct USBankNumberConfiguration: TextFieldElementConfiguration {
        let label = String.Localized.bank_account
        let bankName: String
        let lastFour: String
        let editConfiguration: EditConfiguration = .readOnly

        private var lastFourFormatted: String {
            "\(bankName) ••••\(lastFour)"
        }

        public init(bankName: String, lastFour: String) {
            self.bankName = bankName
            self.lastFour = lastFour
        }

        public func makeDisplayText(for text: String) -> NSAttributedString {
            return NSAttributedString(string: lastFourFormatted)
        }

        func validate(text: String, isOptional: Bool) -> ValidationState {
            stpAssert(!editConfiguration.isEditable, "Validation assumes that the field is read-only")
            return !lastFour.isEmpty ? .valid : .invalid(Error.empty)
        }
    }
}
