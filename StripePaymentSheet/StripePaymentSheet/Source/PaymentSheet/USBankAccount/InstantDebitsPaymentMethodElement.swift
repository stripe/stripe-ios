//
//  InstantDebitsPaymentMethodElement.swift
//  StripePaymentSheet
//
//  Created by Krisjanis Gaidis on 4/11/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

final class InstantDebitsPaymentMethodElement: ContainerElement {
    var elements: [Element] {
        return [formElement]
    }

    private let configuration: PaymentSheetFormFactoryConfig
    private let formElement: FormElement

    private var linkedBankElements: [Element] {
        return [linkedBankInfoSectionElement]
    }
    private let linkedBankInfoSectionElement: SectionElement
    private let linkedBankInfoView: BankAccountInfoView
    private var linkedBank: InstantDebitsLinkedBank?
    private let theme: ElementsUITheme
    var presentingViewControllerDelegate: PresentingViewControllerDelegate?

    var delegate: ElementDelegate?
    var view: UIView {
        return formElement.view
    }
    var mandateString: NSMutableAttributedString? {
        var string: String?
        if linkedBank != nil {
            string = USBankAccountPaymentMethodElement.ContinueMandateText
        } else {
            string = nil
        }
        if let string {
            let links = [
                "terms": URL(string: "https://link.com/terms/ach-authorization")!,
            ]
            let mutableString = STPStringUtils.applyLinksToString(
                template: string,
                links: links
            )
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            mutableString.addAttributes(
                [
                    .paragraphStyle: style,
                    .font: UIFont.preferredFont(forTextStyle: .footnote),
                    .foregroundColor: theme.colors.secondaryText,
                ],
                range: NSRange(location: 0, length: mutableString.length)
            )
            return mutableString
        } else {
            return nil
        }
    }

    var enableCTA: Bool {
        return email != nil
    }
    var email: String? {
        // try to get the email from the EmailElement
        let paymentMethodParams = formElement.updateParams(
            params: IntentConfirmParams(
                type: .stripe(.instantDebits)
            )
        )?.paymentMethodParams
        if let email = paymentMethodParams?.nonnil_billingDetails.email {
            return email
        } else if
            configuration
            .billingDetailsCollectionConfiguration
            .attachDefaultsToPaymentMethod
        {
            // default email
            return configuration.defaultBillingDetails.email
        } else {
            return nil
        }
    }

    init(
        configuration: PaymentSheetFormFactoryConfig,
        titleElement: StaticElement?,
        emailElement: PaymentMethodElement?,
        theme: ElementsUITheme = .default
    ) {
        self.configuration = configuration
        self.linkedBankInfoView = BankAccountInfoView(frame: .zero, theme: theme)
        self.linkedBankInfoSectionElement = SectionElement(
            title: String.Localized.bank_account_sentence_case,
            elements: [StaticElement(view: linkedBankInfoView)],
            theme: theme
        )
        self.linkedBank = nil
        self.linkedBankInfoSectionElement.view.isHidden = true
        self.theme = theme

        let allElements: [Element?] = [
            titleElement,
            emailElement,
            linkedBankInfoSectionElement,
        ]
        let autoSectioningElements = allElements.compactMap { $0 }
        self.formElement = FormElement(
            autoSectioningElements: autoSectioningElements,
            theme: theme
        )
        formElement.delegate = self
        linkedBankInfoView.delegate = self
    }

    func setLinkedBank(_ linkedBank: InstantDebitsLinkedBank) {
        self.linkedBank = linkedBank
        if
            let last4ofBankAccount = linkedBank.last4,
            let bankName = linkedBank.bankName
        {
            linkedBankInfoView.setBankName(text: bankName)
            linkedBankInfoView.setLastFourOfBank(text: "••••\(last4ofBankAccount)")
            formElement.toggleElements(
                linkedBankElements,
                hidden: false,
                animated: true
            )
        }
        self.delegate?.didUpdate(element: self)
    }

    func getLinkedBank() -> InstantDebitsLinkedBank? {
        return linkedBank
    }
}

// MARK: - BankAccountInfoViewDelegate

extension InstantDebitsPaymentMethodElement: BankAccountInfoViewDelegate {

    func didTapXIcon() {
        let hideLinkedBankElement = {
            self.formElement.toggleElements(
                self.linkedBankElements,
                hidden: true,
                animated: true
            )
            self.linkedBank = nil
            self.delegate?.didUpdate(element: self)
        }

        // present a confirmation alert
        if
           let last4BankAccount = self.linkedBank?.last4,
           let presentingDelegate = presentingViewControllerDelegate
        {
            let didTapRemove = UIAlertAction(
                title: String.Localized.remove,
                style: .destructive
            ) { (_) in
                hideLinkedBankElement()
            }
            let didTapCancel = UIAlertAction(
                title: String.Localized.cancel,
                style: .cancel,
                handler: nil
            )
            let alertController = UIAlertController(
                title: String.Localized.removeBankAccount,
                message: String(format: String.Localized.removeBankAccountEndingIn, last4BankAccount),
                preferredStyle: .alert
            )
            alertController.addAction(didTapCancel)
            alertController.addAction(didTapRemove)
            presentingDelegate.presentViewController(
                viewController: alertController,
                completion: nil
            )
        }
        // if we can't present a confirmation alert, just remove
        else {
            hideLinkedBankElement()
        }
    }
}

// MARK: - PaymentMethodElement

extension InstantDebitsPaymentMethodElement: PaymentMethodElement {

    // after a bank is linked, this gets hit to update
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        if
            let updatedParams = formElement.updateParams(params: params),
            let linkedBank
        {
            updatedParams.instantDebitsLinkedBank = linkedBank
            return updatedParams
        }
        return nil
    }
}

// MARK: - ElementDelegate

extension InstantDebitsPaymentMethodElement: ElementDelegate {

    func didUpdate(element: Element) {
        self.delegate?.didUpdate(element: element)
    }

    func continueToNextField(element: Element) {
        self.delegate?.continueToNextField(element: element)
    }
}
