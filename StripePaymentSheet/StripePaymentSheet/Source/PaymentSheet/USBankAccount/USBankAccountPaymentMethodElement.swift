//
//  USBankAccountPaymentMethodElement.swift
//  StripePaymentSheet
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

final class USBankAccountPaymentMethodElement: ContainerElement {
    var elements: [Element] {
        return [formElement]
    }

    var presentingViewControllerDelegate: PresentingViewControllerDelegate?

    var delegate: ElementDelegate?

    var view: UIView {
        return formElement.view
    }
    var mandateString: NSMutableAttributedString?

    private let configuration: PaymentSheetFormFactoryConfig
    private let merchantName: String
    private let formElement: FormElement
    private let bankInfoSectionElement: SectionElement
    private let bankInfoView: BankAccountInfoView
    private let checkboxElement: PaymentMethodElement?
    private var savingAccount: BoolReference
    private let theme: ElementsUITheme
    private var linkedBank: FinancialConnectionsLinkedBank? {
        didSet {
            self.mandateString = Self.attributedMandateText(for: linkedBank, merchantName: merchantName, isSaving: savingAccount.value, configuration: configuration, theme: theme)
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
        "terms": URL(string: "https://stripe.com/legal/ach-payments/authorization")!,
    ]

    static let ContinueMandateText: String = STPLocalizedString("By continuing, you agree to authorize payments pursuant to <terms>these terms</terms>.", "Text providing link to terms for ACH payments")
    static let SaveAccountMandateText: String = STPLocalizedString("By saving your bank account for %@ you agree to authorize payments pursuant to <terms>these terms</terms>.", "Mandate text with link to terms when saving a bank account payment method to a merchant (merchant name replaces %@).")
    static let MicrodepositCopy: String = STPLocalizedString("Stripe will deposit $0.01 to your account in 1-2 business days. Then you’ll get an email with instructions to complete payment to %@.", "Prompt for microdeposit verification before completing purchase with merchant. %@ will be replaced by merchant business name")
    static let MicrodepositCopy_CustomerSheet: String = STPLocalizedString("Stripe will deposit $0.01 to your account in 1-2 business days. Then you'll get an email with instructions to finish saving your bank account with %@.", "Prompt for microdeposit verification before completing saving payment method with merchant. %@ will be replaced by merchant business name")

    var canLinkAccount: Bool {
        let params = self.formElement.updateParams(params: IntentConfirmParams(type: .stripe(.USBankAccount)))
        // If name and email are not collected they won't be verified when updating params.
        // Check if params are valid, and name and email are provided either through the form or through defaults.
        return params != nil && name != nil && email != nil
    }

    var name: String? {
        return self.formElement.updateParams(params: IntentConfirmParams(type: .stripe(.USBankAccount)))?.paymentMethodParams.nonnil_billingDetails.name
            ?? defaultName
    }

    private var defaultName: String? {
        guard configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod else { return nil }
        return configuration.defaultBillingDetails.name
    }

    var email: String? {
        return self.formElement.updateParams(params: IntentConfirmParams(type: .stripe( .USBankAccount)))?.paymentMethodParams.nonnil_billingDetails.email
            ?? defaultEmail
    }

    private var defaultEmail: String? {
        guard configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod else { return nil }
        return configuration.defaultBillingDetails.email
    }

    init(
        configuration: PaymentSheetFormFactoryConfig,
        titleElement: StaticElement,
        nameElement: PaymentMethodElement?,
        emailElement: PaymentMethodElement?,
        phoneElement: PaymentMethodElement?,
        addressElement: PaymentMethodElement?,
        checkboxElement: PaymentMethodElement?,
        savingAccount: BoolReference,
        merchantName: String,
        theme: ElementsUITheme = .default
    ) {
        let collectingName = configuration.billingDetailsCollectionConfiguration.name != .never
        let collectingEmail = configuration.billingDetailsCollectionConfiguration.email != .never
        let hasDefaultName = configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod
            && configuration.defaultBillingDetails.name != nil
        let hasDefaultEmail = configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod
            && configuration.defaultBillingDetails.email != nil

        // Fail loudly: This is an integration error
        assert(
            (collectingName || hasDefaultName) && (collectingEmail || hasDefaultEmail),
            "If name or email are not collected, they must be provided through defaults"
        )

        self.configuration = configuration
        self.bankInfoView = BankAccountInfoView(frame: .zero, theme: theme)
        self.bankInfoSectionElement = SectionElement(title: String.Localized.bank_account_sentence_case,
                                                     elements: [StaticElement(view: bankInfoView)], theme: theme)
        self.linkedBank = nil
        self.bankInfoSectionElement.view.isHidden = true
        self.checkboxElement = checkboxElement

        self.merchantName = merchantName
        self.savingAccount = savingAccount
        self.theme = theme
        let allElements: [Element?] = [
            titleElement,
            nameElement,
            emailElement,
            phoneElement,
            addressElement,
            bankInfoSectionElement,
        ]
        var autoSectioningElements = allElements.compactMap { $0 }
        if let checkboxElement = checkboxElement {
            checkboxElement.view.isHidden = true
            autoSectioningElements.append(checkboxElement)
        }
        self.formElement = FormElement(autoSectioningElements: autoSectioningElements, theme: theme)
        self.formElement.delegate = self
        self.bankInfoView.delegate = self

        savingAccount.didUpdate = { [weak self] value in
            guard let self = self else {
                return
            }
            self.mandateString = Self.attributedMandateText(for: self.linkedBank, merchantName: merchantName, isSaving: value, configuration: configuration, theme: theme)
            self.delegate?.didUpdate(element: self)
        }
    }

    func setLinkedBank(_ linkedBank: FinancialConnectionsLinkedBank) {
        self.linkedBank = linkedBank
        if let last4ofBankAccount = linkedBank.last4,
           let bankName = linkedBank.bankName {
            self.bankInfoView.setBankName(text: bankName)
            self.bankInfoView.setLastFourOfBank(text: "••••\(last4ofBankAccount)")
            formElement.toggleElements(linkedAccountElements, hidden: false, animated: true)
        }
        self.delegate?.didUpdate(element: self)
    }
    func getLinkedBank() -> FinancialConnectionsLinkedBank? {
        return linkedBank
    }

    class func attributedMandateText(for linkedBank: FinancialConnectionsLinkedBank?,
                                     merchantName: String,
                                     isSaving: Bool,
                                     configuration: PaymentSheetFormFactoryConfig,
                                     theme: ElementsUITheme = .default) -> NSMutableAttributedString? {
        guard let linkedBank = linkedBank else {
            return nil
        }

        var mandateText = isSaving ? String(format: Self.SaveAccountMandateText, merchantName) : Self.ContinueMandateText
        if case .customerSheet = configuration, !linkedBank.instantlyVerified {
            mandateText =  String.init(format: Self.MicrodepositCopy_CustomerSheet, merchantName) + "\n" + mandateText
        } else if case .paymentSheet = configuration, !linkedBank.instantlyVerified {
            mandateText =  String.init(format: Self.MicrodepositCopy, merchantName) + "\n" + mandateText
        }
        let formattedString = STPStringUtils.applyLinksToString(template: mandateText, links: links)
        applyStyle(formattedString: formattedString, theme: theme)
        return formattedString
    }

    class func attributedMandateTextSavedPaymentMethod(theme: ElementsUITheme = .default) -> NSMutableAttributedString {
        let mandateText = Self.ContinueMandateText
        let formattedString = STPStringUtils.applyLinksToString(template: mandateText, links: links)
        applyStyle(formattedString: formattedString, theme: theme)
        return formattedString
    }

    private class func applyStyle(formattedString: NSMutableAttributedString, theme: ElementsUITheme = .default) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        formattedString.addAttributes([.paragraphStyle: style,
                                       .font: UIFont.preferredFont(forTextStyle: .footnote),
                                       .foregroundColor: theme.colors.secondaryText,
                                      ],
                                      range: NSRange(location: 0, length: formattedString.length))
    }
}

extension USBankAccountPaymentMethodElement: BankAccountInfoViewDelegate {
    func didTapXIcon() {
        let completionClosure = {
            self.formElement.toggleElements(self.linkedAccountElements, hidden: true, animated: true)
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
        if
            let updatedParams = self.formElement.updateParams(params: params),
            let linkedBank = linkedBank
        {
            updatedParams.paymentMethodParams.usBankAccount?.linkAccountSessionID = linkedBank.sessionId
            updatedParams.financialConnectionsLinkedBank = linkedBank
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
