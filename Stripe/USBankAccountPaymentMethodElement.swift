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
    var mandateString: NSMutableAttributedString?

    private let formElement: FormElement
    private let bankInfoSectionElement: SectionElement
    private let bankInfoView: BankAccountInfoView
    private var linkedBank: ConnectionsSDKResult.LinkedBank?

    private let links: [String: URL] = [
        "terms": URL(string: "https://stripe.com/TODO_____DO_NOT_SHIP")!
    ]

    private let mandateTemplate = STPLocalizedString(
        "By tapping 'Pay', you agree to authorize payments pursuant to <terms>these terms</terms>.",
        "Legal mandate for ACH terms"
    )

    init(titleElement: StaticElement,
         nameElement: PaymentMethodElement,
         emailElement: PaymentMethodElement) {
        self.bankInfoView = BankAccountInfoView()
        self.bankInfoSectionElement = SectionElement(title: STPLocalizedString("Bank account",
                                                                               "Title for collected bank account information"),
                                                     elements: [StaticElement(view: bankInfoView)])
        self.linkedBank = nil
        self.bankInfoSectionElement.view.isHidden = true

        let autoSectioningElements: [Element] = [titleElement,
                                                 nameElement,
                                                 emailElement,
                                                 bankInfoSectionElement]
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

    private func attributedMandateText() -> NSMutableAttributedString {
        let formattedString = applyLinksToString(template: mandateTemplate, links: links)
        applyStyle(formattedString: formattedString)
        return formattedString
    }

    // TODO(wooj): Refactor this code to be common across multiple classes
    private func applyLinksToString(template: String, links:[String: URL]) -> NSMutableAttributedString {
        let formattedString = NSMutableAttributedString()
        STPStringUtils.parseRanges(from: template, withTags: Set<String>(links.keys)) { string, matches in
            formattedString.append(NSAttributedString(string: string))
            for (tag, range) in matches {
                guard range.rangeValue.location != NSNotFound else {
                    assertionFailure("Tag '<\(tag)>' not found")
                    continue
                }

                if let url = links[tag] {
                    formattedString.addAttributes([.link: url], range: range.rangeValue)
                }
            }
        }
        return formattedString
    }

    private func applyStyle(formattedString: NSMutableAttributedString) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        formattedString.addAttributes([.paragraphStyle: style,
                                       .font: UIFont.preferredFont(forTextStyle: .footnote),
                                       .foregroundColor: ElementsUITheme.current.colors.secondaryText
                                      ],
                                      range: NSRange(location: 0, length: formattedString.length))
    }
}

extension USBankAccountPaymentMethodElement: BankAccountInfoViewDelegate {
    func didTapXIcon() {
        self.bankInfoSectionElement.view.isHidden = true
        self.linkedBank = nil
        self.delegate?.didUpdate(element: self)
    }
}

extension USBankAccountPaymentMethodElement: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        if let updatedParams = self.formElement.updateParams(params: params) {
            updatedParams.paymentMethodParams.usBankAccount?.linkAccountSessionID = linkedBank?.sessionId
            self.mandateString = linkedBank?.sessionId != nil
                ? self.attributedMandateText()
                : nil
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
