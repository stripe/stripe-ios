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

    private let merchantName: String
    private let formElement: FormElement
    private let bankInfoSectionElement: SectionElement
    private let bankInfoView: BankAccountInfoView
    private var linkedBank: ConnectionsSDKResult.LinkedBank? {
        didSet {
            self.mandateString = Self.attributedMandateText(for: linkedBank, merchantName: merchantName)
        }
    }

    private static let links: [String: URL] = [
        "terms": URL(string: "https://stripe.com/legal/ach-payments/authorization")!
    ]

    static let InstantVerificationMandateText: String = STPLocalizedString("By continuing, you agree to authorize payments pursuant to <terms>these terms</terms>.", "Text providing link to terms for ACH payments")
    static let MicrodepositVerificationMandateText: String = STPLocalizedString("Stripe will deposit $0.01 to your account in 1-2 business days. Then you’ll get an email with instructions to complete payment to %@. By continuing, you agree to authorize payments pursuant to <terms>these terms</terms>.", "Prompt for microdeposit verification before completing purchase with merchant. %@ will be replaced by merchant business name")

    init(titleElement: StaticElement,
         nameElement: PaymentMethodElement,
         emailElement: PaymentMethodElement,
         merchantName: String) {
        self.bankInfoView = BankAccountInfoView()
        self.bankInfoSectionElement = SectionElement(title: STPLocalizedString("Bank account",
                                                                               "Title for collected bank account information"),
                                                     elements: [StaticElement(view: bankInfoView)])
        self.linkedBank = nil
        self.bankInfoSectionElement.view.isHidden = true

        self.merchantName = merchantName

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

    class func attributedMandateText(for linkedBank: ConnectionsSDKResult.LinkedBank?, merchantName: String) -> NSMutableAttributedString? {
        guard let linkedBank = linkedBank else {
            return nil
        }

        let mandateText = linkedBank.instantlyVerified ?
        Self.InstantVerificationMandateText : String.init(format: Self.MicrodepositVerificationMandateText, merchantName)
        let formattedString = applyLinksToString(template: mandateText, links: links)
        applyStyle(formattedString: formattedString)
        return formattedString
    }

    // TODO(wooj): Refactor this code to be common across multiple classes
    private class func applyLinksToString(template: String, links:[String: URL]) -> NSMutableAttributedString {
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

    private class func applyStyle(formattedString: NSMutableAttributedString) {
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
