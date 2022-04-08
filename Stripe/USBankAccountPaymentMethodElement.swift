//
//  USBankAccountPaymentMethodElement.swift
//  StripeiOS
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore

final class USBankAccountPaymentMethodElement : Element {
    var delegate: ElementDelegate? = nil

    var view: UIView {
        return formElement.view
    }

    let formElement: FormElement
    let bankInfoSectionElement: SectionElement
    let bankInfoView: BankAccountInfoView

    init(nameElement: PaymentMethodElement,
         emailElement: PaymentMethodElement,
         spacerElement: StaticElement) {
        self.bankInfoView = BankAccountInfoView()
        self.bankInfoSectionElement = SectionElement(title: STPLocalizedString("Bank account",
                                                                               "Title for collected bank account information"),
                                                     elements: [StaticElement(view: bankInfoView)])
        self.bankInfoSectionElement.view.isHidden = true

        let autoSectioningElements: [Element] = [nameElement,
                                                 emailElement,
                                                 bankInfoSectionElement,
                                                 spacerElement]
        self.formElement = FormElement(autoSectioningElements: autoSectioningElements)
        self.formElement.delegate = self
        self.bankInfoView.delegate = self
    }

    func setBankDetails(bankName: String, last4OfBankAccount: String) {
        let sanitizedBankAccount = last4OfBankAccount
            .stp_stringByRemovingCharacters(from: CharacterSet.stp_invertedAsciiDigit)
            .suffix(4)

        self.bankInfoView.setBankName(text: bankName)
        self.bankInfoView.setLastFourOfBank(text: "****\(sanitizedBankAccount)")

        self.bankInfoSectionElement.view.isHidden = false
        self.delegate?.didUpdate(element: self)
    }
}

extension USBankAccountPaymentMethodElement: BankAccountInfoViewDelegate {
    func didTapXIcon() {
        self.bankInfoSectionElement.view.isHidden = true
        self.delegate?.didUpdate(element: self)
    }
}

extension USBankAccountPaymentMethodElement: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        if let updatedParams = self.formElement.updateParams(params: params) {
            return updatedParams
        }
        return nil
    }
}

extension USBankAccountPaymentMethodElement: ElementDelegate {
    func didUpdate(element: Element) {
        self.delegate?.didUpdate(element: element)
    }

    func continueToNextField(element: Element) {
        self.delegate?.continueToNextField(element: element)
    }
}
