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
    var linkedBank: ConnectionsSDKResult.LinkedBank?

    init(nameElement: PaymentMethodElement,
         emailElement: PaymentMethodElement,
         spacerElement: StaticElement) {
        self.bankInfoView = BankAccountInfoView()
        self.bankInfoSectionElement = SectionElement(title: STPLocalizedString("Bank account",
                                                                               "Title for collected bank account information"),
                                                     elements: [StaticElement(view: bankInfoView)])
        self.linkedBank = nil
        self.bankInfoSectionElement.view.isHidden = true

        let autoSectioningElements: [Element] = [nameElement,
                                                 emailElement,
                                                 bankInfoSectionElement,
                                                 spacerElement]
        self.formElement = FormElement(autoSectioningElements: autoSectioningElements)
        self.formElement.delegate = self
        self.bankInfoView.delegate = self
    }

    func setLinkedBank(_ linkedBank: ConnectionsSDKResult.LinkedBank) {
        self.linkedBank = linkedBank
        if let last4ofBankAccount = linkedBank.last4,
           let bankName = linkedBank.bankName {
            self.bankInfoView.setBankName(text: bankName)
            self.bankInfoView.setLastFourOfBank(text: "••••\(last4ofBankAccount)")
            self.bankInfoSectionElement.view.isHidden = false
        }
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
            updatedParams.paymentMethodParams.usBankAccount?.linkAccountSessionID = linkedBank?.sessionId
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
