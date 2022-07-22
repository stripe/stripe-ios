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
    var presentingViewControllerDelegate: PresentingViewControllerDelegate? = nil

    var delegate: ElementDelegate? = nil

    var view: UIView {
        return formElement.view
    }
    var mandateString: NSMutableAttributedString?

    private let merchantName: String
    private let formElement: FormElement
    private let bankInfoSectionElement: SectionElement
    private let bankInfoView: BankAccountInfoView
    private let checkboxElement: PaymentMethodElement?
    private var savingAccount: BoolReference
    private let theme: ElementsUITheme
    private var linkedBank: LinkedBank? {
        didSet {
            self.mandateString = Self.attributedMandateText(for: linkedBank, merchantName: merchantName, isSaving: savingAccount.value, theme: theme)
        }
    }

    private var linkedAccountElements: [Element] {
        var elements: [Element] = [bankInfoSectionElement]
        if let checkboxElement = checkboxElement {
            elements.append(checkboxElement)
        }
        return elements
    }

    private static let links: [String: URL] = [
        "terms": URL(string: "https://stripe.com/legal/ach-payments/authorization")!
    ]

    static let ContinueMandateText: String = STPLocalizedString("By continuing, you agree to authorize payments pursuant to <terms>these terms</terms>.", "Text providing link to terms for ACH payments")
    static let SaveAccountMandateText: String = STPLocalizedString("By saving your bank account for %@ you agree to authorize payments pursuant to <terms>these terms</terms>.", "Mandate text with link to terms when saving a bank account payment method to a merchant (merchant name replaces %@).")
    static let MicrodepositCopy: String = STPLocalizedString("Stripe will deposit $0.01 to your account in 1-2 business days. Then you’ll get an email with instructions to complete payment to %@.", "Prompt for microdeposit verification before completing purchase with merchant. %@ will be replaced by merchant business name")


    var canLinkAccount: Bool {
        return self.formElement.updateParams(params: IntentConfirmParams(type: .USBankAccount)) != nil
    }

    var name: String? {
        return self.formElement.updateParams(params: IntentConfirmParams(type: .USBankAccount))?.paymentMethodParams.nonnil_billingDetails.name
    }

    var email: String? {
        return self.formElement.updateParams(params: IntentConfirmParams(type: .USBankAccount))?.paymentMethodParams.nonnil_billingDetails.email
    }
    
    init(titleElement: StaticElement,
         nameElement: PaymentMethodElement,
         emailElement: PaymentMethodElement,
         checkboxElement: PaymentMethodElement?,
         savingAccount: BoolReference,
         merchantName: String,
         theme: ElementsUITheme = .default) {
        self.bankInfoView = BankAccountInfoView(frame: .zero, theme: theme)
        self.bankInfoSectionElement = SectionElement(title: STPLocalizedString("Bank account",
                                                                               "Title for collected bank account information"),
                                                     elements: [StaticElement(view: bankInfoView)], theme: theme)
        self.linkedBank = nil
        self.bankInfoSectionElement.view.isHidden = true
        self.checkboxElement = checkboxElement

        self.merchantName = merchantName
        self.savingAccount = savingAccount
        self.theme = theme
        var autoSectioningElements: [Element] = [titleElement,
                                                 nameElement,
                                                 emailElement,
                                                 bankInfoSectionElement]
        if let checkboxElement = checkboxElement {
            checkboxElement.view.isHidden = true
            autoSectioningElements.append(checkboxElement)
        }
        self.formElement = FormElement(autoSectioningElements: autoSectioningElements, theme: theme)
        self.formElement.delegate = self
        self.bankInfoView.delegate = self

        defer {
            savingAccount.didUpdate = { [weak self] value in
                guard let self = self else {
                    return
                }
                self.mandateString = Self.attributedMandateText(for: self.linkedBank, merchantName: merchantName, isSaving: value, theme: theme)
                self.delegate?.didUpdate(element: self)
            }
        }
    }

    func setLinkedBank(_ linkedBank: LinkedBank) {
        self.linkedBank = linkedBank
        if let last4ofBankAccount = linkedBank.last4,
           let bankName = linkedBank.bankName {
            self.bankInfoView.setBankName(text: bankName)
            self.bankInfoView.setLastFourOfBank(text: "••••\(last4ofBankAccount)")
            formElement.setElements(linkedAccountElements, hidden: false, animated: true)
        }
        self.delegate?.didUpdate(element: self)
    }

    class func attributedMandateText(for linkedBank: LinkedBank?,
                                     merchantName: String,
                                     isSaving: Bool,
                                     theme: ElementsUITheme = .default) -> NSMutableAttributedString? {
        guard let linkedBank = linkedBank else {
            return nil
        }

        var mandateText = isSaving ? String(format: Self.SaveAccountMandateText, merchantName) : Self.ContinueMandateText
        if !linkedBank.instantlyVerified {
            mandateText =  String.init(format: Self.MicrodepositCopy, merchantName) + "\n" + mandateText
        }
        let formattedString = applyLinksToString(template: mandateText, links: links)
        applyStyle(formattedString: formattedString, theme: theme)
        return formattedString
    }

    class func attributedMandateTextSavedPaymentMethod(theme: ElementsUITheme = .default) -> NSMutableAttributedString {
        let mandateText = Self.ContinueMandateText
        let formattedString = applyLinksToString(template: mandateText, links: links)
        applyStyle(formattedString: formattedString, theme: theme)
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

    private class func applyStyle(formattedString: NSMutableAttributedString, theme: ElementsUITheme = .default) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        formattedString.addAttributes([.paragraphStyle: style,
                                       .font: UIFont.preferredFont(forTextStyle: .footnote),
                                       .foregroundColor: theme.colors.secondaryText
                                      ],
                                      range: NSRange(location: 0, length: formattedString.length))
    }
}

extension USBankAccountPaymentMethodElement: BankAccountInfoViewDelegate {
    func didTapXIcon() {
        let completionClosure = {
            self.formElement.setElements(self.linkedAccountElements, hidden: true, animated: true)
            self.linkedBank = nil
            self.delegate?.didUpdate(element: self)
        }

        guard let last4BankAccount = self.linkedBank?.last4,
              let presentingDelegate = presentingViewControllerDelegate else {
            completionClosure()
            return
        }

        let didTapAlert = UIAlertAction(title: String.Localized.remove, style: .destructive) { (_) in
            completionClosure()
        }
        let didTapCancel = UIAlertAction(title: String.Localized.cancel,
                                   style: .cancel,
                                   handler: nil)
        let alertController = UIAlertController(title: String.Localized.removeBankAccount,
                                                message: String(format: String.Localized.removeBankAccountEndingIn, last4BankAccount),
                                                preferredStyle: .alert)
        alertController.addAction(didTapCancel)
        alertController.addAction(didTapAlert)
        presentingDelegate.presentViewController(viewController: alertController, completion: nil)
    }
}

extension USBankAccountPaymentMethodElement: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        if let updatedParams = self.formElement.updateParams(params: params),
           let linkedBank = linkedBank {
            updatedParams.paymentMethodParams.usBankAccount?.linkAccountSessionID = linkedBank.sessionId
            updatedParams.linkedBank = linkedBank
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
