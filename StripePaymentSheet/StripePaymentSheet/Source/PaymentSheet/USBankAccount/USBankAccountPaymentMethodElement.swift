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
    var linkedBank: FinancialConnectionsLinkedBank? {
        didSet {
            updateLinkedBankUI()
            self.delegate?.didUpdate(element: self)
        }
    }

    let phoneElement: PhoneNumberElement?
    private(set) var mandateString: NSMutableAttributedString?
    private let configuration: PaymentSheetFormFactoryConfig
    private let merchantName: String
    private let formElement: FormElement
    private let bankInfoSectionElement: SectionElement
    private let bankInfoView: BankAccountInfoView
    private let saveCheckboxElement: PaymentMethodElementWrapper<CheckboxElement>?
    private let defaultCheckboxElement: Element?
    private var savingAccount: BoolReference
    private let theme: ElementsAppearance

    private var linkedAccountElements: [Element] {
        [bankInfoSectionElement, saveCheckboxElement, saveCheckboxElement?.element.isSelected ?? false ? defaultCheckboxElement : nil].compactMap { $0 }
    }

    private static let links: [String: URL] = [
        "terms": URL(string: "https://stripe.com/legal/ach-payments/authorization")!,
    ]

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
        subtitleElement: SubtitleElement,
        nameElement: PaymentMethodElementWrapper<TextFieldElement>?,
        emailElement: PaymentMethodElementWrapper<TextFieldElement>?,
        phoneElement: PaymentMethodElementWrapper<PhoneNumberElement>?,
        addressElement: PaymentMethodElementWrapper<AddressSectionElement>?,
        saveCheckboxElement: PaymentMethodElementWrapper<CheckboxElement>?,
        defaultCheckboxElement: Element?,
        savingAccount: BoolReference,
        merchantName: String,
        initialLinkedBank: FinancialConnectionsLinkedBank?,
        appearance: PaymentSheet.Appearance = .default
    ) {
        let theme = appearance.asElementsTheme
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

        self.phoneElement = phoneElement?.element

        self.configuration = configuration
        self.linkedBank = initialLinkedBank
        self.bankInfoView = BankAccountInfoView(frame: .zero, appearance: appearance)
        self.bankInfoSectionElement = SectionElement(title: String.Localized.bank_account_sentence_case,
                                                     elements: [StaticElement(view: bankInfoView)], theme: theme)
        self.bankInfoSectionElement.view.isHidden = true
        self.saveCheckboxElement = saveCheckboxElement
        saveCheckboxElement?.view.isHidden = true
        self.defaultCheckboxElement = defaultCheckboxElement
        defaultCheckboxElement?.view.isHidden = true
        self.merchantName = merchantName
        self.savingAccount = savingAccount
        self.theme = theme
        let allElements: [Element?] = [
            subtitleElement,
            nameElement,
            emailElement,
            phoneElement,
            addressElement,
            bankInfoSectionElement,
            saveCheckboxElement,
            defaultCheckboxElement,
        ]
        let autoSectioningElements = allElements.compactMap { $0 }
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
        updateLinkedBankUI(animated: false)
    }

    func updateLinkedBankUI(animated: Bool = true) {
        // Why are last4 and bank name optional? What does it mean if we set `self.linkedBank` but we're not showing the linked bank to the customer?
        if let last4ofBankAccount = linkedBank?.last4,
           let bankName = linkedBank?.bankName {
            bankInfoView.setBankName(text: bankName)
            bankInfoView.setLastFourOfBank(text: "••••\(last4ofBankAccount)")
            formElement.toggleElements(linkedAccountElements, hidden: false, animated: animated)
        } else {
            formElement.toggleElements(linkedAccountElements, hidden: true, animated: animated)
        }
        mandateString = Self.attributedMandateText(
            for: linkedBank,
            merchantName: merchantName,
            isSaving: savingAccount.value,
            configuration: configuration,
            theme: theme
        )
    }

    static func attributedMandateText(
        for linkedBank: FinancialConnectionsLinkedBank?,
        merchantName: String,
        isSaving: Bool,
        configuration: PaymentSheetFormFactoryConfig,
        theme: ElementsAppearance = .default
    ) -> NSMutableAttributedString? {
        guard let linkedBank else {
            return nil
        }

        var mandateText = isSaving ? String(format: Self.SaveAccountMandateText, merchantName) : String.Localized.bank_continue_mandate_text
        if case .customerSheet = configuration, !linkedBank.instantlyVerified {
            mandateText =  String.init(format: Self.MicrodepositCopy_CustomerSheet, merchantName) + "\n" + mandateText
        } else if case .paymentElement = configuration, !linkedBank.instantlyVerified {
            mandateText =  String.init(format: Self.MicrodepositCopy, merchantName) + "\n" + mandateText
        }
        let formattedString = STPStringUtils.applyLinksToString(template: mandateText, links: links)
        applyStyle(formattedString: formattedString, alignment: .center, theme: theme)
        return formattedString
    }

    static func attributedMandateTextSavedPaymentMethod(alignment: NSTextAlignment = .center, theme: ElementsAppearance) -> NSMutableAttributedString {
        let mandateText = String.Localized.bank_continue_mandate_text
        let formattedString = STPStringUtils.applyLinksToString(template: mandateText, links: links)
        applyStyle(formattedString: formattedString, alignment: alignment, theme: theme)
        return formattedString
    }

    private static func applyStyle(formattedString: NSMutableAttributedString, alignment: NSTextAlignment, theme: ElementsAppearance = .default) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        formattedString.addAttributes([.paragraphStyle: style,
                                       .font: theme.fonts.footnote,
                                       .foregroundColor: theme.colors.secondaryText,
                                      ],
                                      range: NSRange(location: 0, length: formattedString.length))
    }
}

extension USBankAccountPaymentMethodElement: BankAccountInfoViewDelegate {
    func didTapXIcon() {
        let completionClosure = {
            self.linkedBank = nil
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
                                                message: String(format: String.Localized.bank_account_xxxx, last4BankAccount),
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
