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

    let nameElement: TextFieldElement?
    let emailElement: TextFieldElement?
    let phoneElement: PhoneNumberElement?
    let addressElement: AddressSectionElement?

    private var linkedBankElements: [Element] {
        return [linkedBankInfoSectionElement]
    }
    private let linkedBankInfoSectionElement: SectionElement
    private let linkedBankInfoView: BankAccountInfoView
    private var linkedBank: InstantDebitsLinkedBank?
    private let theme: ElementsAppearance
    var presentingViewControllerDelegate: PresentingViewControllerDelegate?

    var delegate: ElementDelegate?
    var view: UIView {
        return formElement.view
    }
    var mandateString: NSMutableAttributedString? {
        var string: String?
        if linkedBank != nil {
            string = String.Localized.bank_continue_mandate_text
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

    var name: String? {
        nameElement?.text ?? defaultName
    }

    var defaultName: String? {
        guard configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod else { return nil }
        return configuration.defaultBillingDetails.name
    }

    var email: String? {
        emailElement?.text ?? defaultEmail
    }

    var defaultEmail: String? {
        guard configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod else { return nil }
        return configuration.defaultBillingDetails.email
    }

    var phone: String? {
        phoneElement?.phoneNumber?.string(as: .e164) ?? defaultPhone
    }

    var defaultPhone: String? {
        guard configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod else { return nil }
        return configuration.defaultBillingDetails.phone
    }

    var address: PaymentSheet.Address {
        PaymentSheet.Address(
            city: addressElement?.city?.text ?? defaultAddress?.city,
            country: addressElement?.selectedCountryCode ?? defaultAddress?.country,
            line1: addressElement?.line1?.text ?? defaultAddress?.line1,
            line2: addressElement?.line2?.text ?? defaultAddress?.line2,
            postalCode: addressElement?.postalCode?.text ?? defaultAddress?.postalCode,
            state: addressElement?.state?.rawData ?? defaultAddress?.state
        )
    }

    var defaultAddress: PaymentSheet.Address? {
        guard configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod else { return nil }
        return configuration.defaultBillingDetails.address
    }

    var billingDetails: ElementsSessionContext.BillingDetails {
        let billingAddress = ElementsSessionContext.BillingDetails.Address(
            city: address.city,
            country: address.country,
            line1: address.line1,
            line2: address.line2,
            postalCode: address.postalCode,
            state: address.state
        )

        return ElementsSessionContext.BillingDetails(
            name: name,
            email: email,
            phone: phone,
            address: billingAddress
        )
    }

    var enableCTA: Bool {
        let nameValid: Bool = {
            // If the name field isn't shown, we treat the name as valid.
            guard nameElement != nil else { return true }
            // Otherwise, check if the name field is not empty.
            return name?.isEmpty == false
        }()

        let emailValid: Bool = {
            if emailElement != nil {
                // If the email field is shown, make sure we have a valid email.
                return STPEmailAddressValidator.stringIsValidEmailAddress(email)
            } else {
                // Otherwise, make sure the default email provided is not empty.
                return defaultEmail?.isEmpty == false
            }
        }()

        let phoneValid: Bool = {
            // If the phone field isn't shown, we treat the phone number as valid.
            guard phoneElement != nil else { return true }
            // Otherwise, check if the phone field is not empty.
            return phone?.isEmpty == false
        }()

        let addressValid: Bool = {
            // If the address section isn't shown, we treat the address as valid.
            guard addressElement != nil else { return true }
            // If the address section is shown, the address is valid if all fields (except line2) are not empty.
            return address.isValid
        }()

        return nameValid && emailValid && phoneValid && addressValid
    }

    init(
        configuration: PaymentSheetFormFactoryConfig,
        titleElement: StaticElement?,
        nameElement: PaymentMethodElementWrapper<TextFieldElement>?,
        emailElement: PaymentMethodElementWrapper<TextFieldElement>?,
        phoneElement: PaymentMethodElementWrapper<PhoneNumberElement>?,
        addressElement: PaymentMethodElementWrapper<AddressSectionElement>?,
        theme: ElementsAppearance = .default
    ) {
        self.configuration = configuration
        self.linkedBankInfoView = BankAccountInfoView(frame: .zero, theme: theme)
        self.linkedBankInfoSectionElement = SectionElement(
            title: String.Localized.bank_account_sentence_case,
            elements: [StaticElement(view: linkedBankInfoView)],
            theme: theme
        )

        self.nameElement = nameElement?.element
        self.emailElement = emailElement?.element
        self.phoneElement = phoneElement?.element
        self.addressElement = addressElement?.element

        self.linkedBank = nil
        self.linkedBankInfoSectionElement.view.isHidden = true
        self.theme = theme

        let allElements: [Element?] = [
            titleElement,
            nameElement,
            emailElement,
            phoneElement,
            addressElement,
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
                message: String(format: String.Localized.bank_account_xxxx, last4BankAccount),
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

private extension PaymentSheet.Address {
    /// An address is valid if all fields except `line2` are not empty.
    var isValid: Bool {
        city?.isEmpty == false &&
        country?.isEmpty == false &&
        line1?.isEmpty == false &&
        postalCode?.isEmpty == false &&
        state?.isEmpty == false
    }
}
