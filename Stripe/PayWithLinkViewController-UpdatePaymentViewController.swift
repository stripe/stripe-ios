//
//  PayWithLinkViewController-UpdatePaymentViewController.swift
//  StripeiOS
//
//  Created by Nick Porter on 1/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol UpdatePaymentViewControllerDelegate: AnyObject {
    func didUpdate(paymentMethod: ConsumerPaymentDetails)
}

extension PayWithLinkViewController {

    /// For internal SDK use only
    @objc(STP_Internal_UpdatePaymentViewController)
    final class UpdatePaymentViewController: BaseViewController {
        weak var delegate: UpdatePaymentViewControllerDelegate?
        let linkAccount: PaymentSheetLinkAccount
        let intent: Intent
        var configuration: PaymentSheet.Configuration
        let paymentMethod: ConsumerPaymentDetails

        private let titleLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .title)
            label.textColor = .linkPrimaryText
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            label.text = String.Localized.update_card
            return label
        }()
        
        private let thisIsYourDefaultLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .bodyEmphasized)
            label.textColor = .linkSecondaryText
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            label.text = STPLocalizedString(
                "This is your default",
                "Text of a label indicating that a payment method is the default."
            )
            return label
        }()

        private lazy var updateButton: ConfirmButton = .makeLinkButton(
            callToAction: .custom(title: String.Localized.update_card)
        ) { [weak self] in
            self?.updateCard()
        }
        
        private lazy var cancelButton: Button = {
            let button = Button(configuration: .linkSecondary(), title: String.Localized.cancel)
            button.addTarget(self, action: #selector(didSelectCancel), for: .touchUpInside)
            button.adjustsFontForContentSizeCategory = true
            return button
        }()
        
        private lazy var errorLabel: UILabel = {
            return ElementsUI.makeErrorLabel(theme: LinkUI.appearance.asElementsTheme)
        }()
        
        // Don't show checkbox if payment method is already default
        private lazy var updatePaymentDetailsView = CardDetailsEditView(
            checkboxText: paymentMethod.isDefault ? nil : STPLocalizedString(
                "Set as default payment method",
                "Label of a checkbox that when checked makes a payment method as the default one."
            ),
            includeCardScanning: false,
            prefillDetails: paymentMethod.prefillDetails,
            inputMode: .panLocked,
            configuration: configuration
        )

        init(linkAccount: PaymentSheetLinkAccount, context: Context, paymentMethod: ConsumerPaymentDetails) {
            self.linkAccount = linkAccount
            self.intent = context.intent
            self.configuration = context.configuration
            self.configuration.linkPaymentMethodsOnly = true
            self.paymentMethod = paymentMethod
            super.init(context: context)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            self.updatePaymentDetailsView.delegate = self
            view.backgroundColor = .linkBackground
            view.directionalLayoutMargins = LinkUI.contentMargins
            errorLabel.isHidden = true
            
            let stackView = UIStackView(arrangedSubviews: [
                titleLabel,
                updatePaymentDetailsView,
                errorLabel,
                thisIsYourDefaultLabel,
                updateButton,
                cancelButton
            ])

            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.alignment = .center
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: titleLabel)
            stackView.translatesAutoresizingMaskIntoConstraints = false

            let scrollView = LinkKeyboardAvoidingScrollView()
            scrollView.keyboardDismissMode = .interactive
            scrollView.addSubview(stackView)

            contentView.addAndPinSubview(scrollView)

            if !paymentMethod.isDefault {
                thisIsYourDefaultLabel.isHidden = true
                stackView.setCustomSpacing(LinkUI.largeContentSpacing, after: updatePaymentDetailsView)
            } else {
                stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: thisIsYourDefaultLabel)
            }
            
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: LinkUI.contentMargins.top),
                stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -LinkUI.contentMargins.bottom),
                stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

                titleLabel.leadingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.leadingAnchor,
                    constant: LinkUI.contentMargins.leading),
                titleLabel.trailingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                    constant: -LinkUI.contentMargins.trailing),

                updatePaymentDetailsView.leadingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.leadingAnchor,
                    constant: LinkUI.contentMargins.leading),
                updatePaymentDetailsView.trailingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                    constant: -LinkUI.contentMargins.trailing),
                
                thisIsYourDefaultLabel.leadingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.leadingAnchor,
                    constant: LinkUI.contentMargins.leading),
                thisIsYourDefaultLabel.trailingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                    constant: -LinkUI.contentMargins.trailing),
                
                updateButton.leadingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.leadingAnchor,
                    constant: LinkUI.contentMargins.leading),
                updateButton.trailingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                    constant: -LinkUI.contentMargins.trailing),
                
                cancelButton.leadingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.leadingAnchor,
                    constant: LinkUI.contentMargins.leading),
                cancelButton.trailingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                    constant: -LinkUI.contentMargins.trailing)
            ])

            updateButton.update(state: .disabled)
        }

        func updateCard() {
            updateErrorLabel(for: nil)
            guard let paymentMethodParams = updatePaymentDetailsView.paymentMethodParams,
            let expiryMonth = paymentMethodParams.card?.expMonth as? Int,
            let expiryYear = paymentMethodParams.card?.expYear as? Int,
            let billingDetails = paymentMethodParams.billingDetails else {
                return
            }
            
            updateButton.update(state: .processing)
            
            let updateDefault = paymentMethod.isDefault ? true : self.updatePaymentDetailsView.checkboxView.isSelected
            
            // When updating a card that is not the default and you send isDefault=false to the server you get
            // "Can't unset payment details when it's not the default", so send nil instead of false
            let updateParams = UpdatePaymentDetailsParams(
                isDefault: updateDefault ? true : nil,
                details: .card(
                    expiryDate: .init(month: expiryMonth, year: expiryYear),
                    billingDetails: billingDetails
                )
            )

            linkAccount.updatePaymentDetails(id: paymentMethod.stripeID, updateParams: updateParams) { [weak self] result in
                
                switch result {
                case .success(let updatedPaymentDetails):
                    // Updates to CVC only get applied when the intent is confirmed so we manually add them here
                    // instead of including in the /update API call
                    if let cvc = paymentMethodParams.card?.cvc,
                       case .card(let card) = updatedPaymentDetails.details {
                        card.cvc = cvc
                    }
                    
                    self?.updateButton.update(state: .succeeded, style: nil, callToAction: nil, animated: true) {
                        self?.delegate?.didUpdate(paymentMethod: updatedPaymentDetails)
                        self?.navigationController?.popViewController(animated: true)
                    }

                case .failure(let error):
                    self?.updateErrorLabel(for: error)
                    self?.updatePaymentDetailsView.isUserInteractionEnabled = true
                    self?.updateButton.update(state: .enabled)
                    break
                }
            }
            
            updatePaymentDetailsView.isUserInteractionEnabled = false
        }
        
        @objc func didSelectCancel() {
            self.navigationController?.popViewController(animated: true)
        }
        
        func updateErrorLabel(for error: Error?) {
            errorLabel.text = error?.nonGenericDescription
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                self.errorLabel.setHiddenIfNecessary(error == nil)
            }
        }
        
    }

}

extension PayWithLinkViewController.UpdatePaymentViewController: ElementDelegate {
    
    func didUpdate(element: Element) {
        updateErrorLabel(for: nil)
        guard let element = element as? CardDetailsEditView else {
            return
        }
        
        updateButton.update(state: element.hasCompleteDetails ? .enabled : .disabled)
    }
    
    func continueToNextField(element: Element) {
        guard let element = element as? CardDetailsEditView else {
            return
        }
        
        updateButton.update(state: element.hasCompleteDetails ? .enabled : .disabled)
    }
    
}

// MARK: UpdatePaymentDetailsParams

struct UpdatePaymentDetailsParams {
    enum DetailsType {
        case card(expiryDate: CardExpiryDate, billingDetails: STPPaymentMethodBillingDetails? = nil)
        // updating bank not supported
    }

    let isDefault: Bool?
    let details: DetailsType?

    init(isDefault: Bool? = nil, details: DetailsType? = nil) {
        self.isDefault = isDefault
        self.details = details
    }
}

