// Copyright © 2026 Stripe, Inc. All rights reserved.

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripePaymentsUI
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

extension PaymentSheetFormFactory {
    func makePayto() -> PaymentMethodElement {
        let name = configuration.billingDetailsCollectionConfiguration.name != .never ? makeName() : nil
        let email = configuration.billingDetailsCollectionConfiguration.email != .never ? makeEmail() : nil
        let phone = configuration.billingDetailsCollectionConfiguration.phone == .always ? makePhone() : nil
        let previousPayID = getPreviousCustomerInput(for: "payto[pay_id]")
        let method = makeDropdown(
            label: String.Localized.payto_payment_details,
            apiPath: "payto_entry_method",
            options: [(String.Localized.payto_bank_account, "bank_account"), ("PayID", "pay_id")],
            defaultValue: previousPayID == nil ? "bank_account" : "pay_id",
            paramsUpdater: { _, params in
                // A form can be submitted repeatedly after switching entry methods.
                params.paymentMethodParams.additionalAPIParameters["payto[pay_id]"] = nil
                params.paymentMethodParams.additionalAPIParameters["payto[bsb_number]"] = nil
                params.paymentMethodParams.additionalAPIParameters["payto[account_number]"] = nil
            }
        )
        let bankDetails = FormElement(autoSectioningElements: [
            makeBSB(apiPath: "payto[bsb_number]"),
            makeAUBECSAccountNumber(apiPath: "payto[account_number]"),
        ], theme: theme)
        let payID = PaymentMethodElementWrapper(
            PaytoPayIDConfiguration(defaultValue: previousPayID), theme: theme
        ) { field, params in
            params.paymentMethodParams.additionalAPIParameters["payto[pay_id]"] = field.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return params
        }
        let payIDDetails = SectionElement(elements: [payID], theme: theme)
        let emailSection = email.map { SectionElement(elements: [$0], theme: theme) }
        let address = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
            as? PaymentMethodElementWrapper<AddressSectionElement>
        connectBillingDetailsFields(addressElement: address, phoneElement: phone)

        let terms = String(format: String.Localized.payto_terms, configuration.merchantDisplayName)
        let disclosure = makeMandate(mandateText: STPStringUtils.applyLinksToString(
            template: terms,
            links: ["terms": URL(string: "https://assets.ctfassets.net/fzn2n1nzq965/6z1MWLed7Q7DwHK9Jj7sBN/8b35c474e1bd6872c735cee58722f8be/PayTo_Customer_Terms.pdf")!]
        ))
        let reuse = isSettingUp
            ? makeMandate(mandateText: String(format: String.Localized.payto_reuse_mandate, configuration.merchantDisplayName)) : nil
        let elements: [Element?] = [name, emailSection, phone, method, bankDetails, payIDDetails, address, disclosure, reuse]
        let form = FormElement(autoSectioningElements: elements.compactMap { $0 }, theme: theme)
        let alwaysCollectEmail = configuration.billingDetailsCollectionConfiguration.email == .always
        let updateEntryMethod: (Int) -> Void = { [weak form] index in
            form?.toggleElements([bankDetails], hidden: index == 1, animated: false)
            form?.toggleElements([payIDDetails], hidden: index == 0, animated: false)
            if let emailSection {
                form?.toggleElements([emailSection], hidden: index == 0 && !alwaysCollectEmail, animated: false)
            }
        }
        method.element.didUpdate = updateEntryMethod
        updateEntryMethod(method.element.selectedIndex)
        return makeDefaultsApplierWrapper(for: form)
    }
}

private struct PaytoPayIDConfiguration: TextFieldElementConfiguration {
    let label = "PayID"
    let defaultValue: String?

    func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
        .init(type: .emailAddress, textContentType: .none, autocapitalization: .none)
    }

    func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            return .invalid(TextFieldElement.Error.empty(localizedDescription: .Localized.payto_invalid_payid))
        }
        if STPEmailAddressValidator.stringIsValidEmailAddress(value) {
            return .valid
        }
        // Strip only phone formatting characters; letters must not be silently discarded.
        let separators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "()-"))
        let number = value.components(separatedBy: separators).joined()
        if number.hasPrefix("+") {
            if let phone = PhoneNumber.fromE164(number), phone.isComplete {
                return .valid
            }
        } else if number.unicodeScalars.allSatisfy(CharacterSet.stp_asciiDigit.contains),
                  number.count == 9 || (number.count == 10 && number.hasPrefix("0")) {
            // Numbers without a country prefix are Australian national numbers.
            return .valid
        }
        return .invalid(TextFieldElement.Error.invalid(localizedDescription: .Localized.payto_invalid_payid))
    }
}
