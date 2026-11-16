//
//  PayWithLinkViewController-AddShippingAddressViewController.swift
//  StripePaymentSheet
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripePaymentsUI
@_spi(InternalOnlyAPI) import StripeUICore

protocol AddShippingAddressViewControllerDelegate: AnyObject {
    func didAdd(shippingAddress: ShippingAddressesResponse.ShippingAddress)
}

extension PayWithLinkViewController {

    /// Collects a new shipping address and saves it to the Link account.
    /// For internal SDK use only
    @objc(STP_Internal_AddShippingAddressViewController)
    final class AddShippingAddressViewController: BaseViewController {
        weak var delegate: AddShippingAddressViewControllerDelegate?
        let linkAccount: PaymentSheetLinkAccount

        private lazy var theme: ElementsAppearance = {
            var theme = LinkUI.appearance.asElementsTheme

            if let primaryColor = context.linkAppearance?.colors?.primary {
                theme.colors.primary = primaryColor
            }

            return theme
        }()

        private lazy var addressSection: AddressSectionElement = {
            let addressSection = AddressSectionElement(
                title: String.Localized.shipping_address,
                countries: context.allowedShippingCountries,
                defaultFieldsToCollect: .all,
                disableAutocomplete: true,
                additionalFields: .init(name: .enabled(isOptional: false)),
                theme: theme
            )
            addressSection.delegate = self
            return addressSection
        }()

        private lazy var errorView: LinkHintMessageView = {
            let view = LinkHintMessageView(message: nil, style: .error)
            view.isHidden = true
            return view
        }()

        private lazy var saveButton: ConfirmButton = .makeLinkButton(
            callToAction: .custom(title: String.Localized.save_address),
            showProcessingLabel: false,
            linkAppearance: context.linkAppearance,
            didTapWhenDisabled: { [weak self] in
                guard let self else { return }
                self.updateErrorLabel(for: nil)
#if !os(visionOS)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
#endif
                self.addressSection.showAllValidationErrors()
            }
        ) { [weak self] in
            self?.saveShippingAddress()
        }

        init(linkAccount: PaymentSheetLinkAccount, context: Context) {
            self.linkAccount = linkAccount
            super.init(
                context: context,
                navigationTitle: STPLocalizedString(
                    "Add shipping address",
                    "Title for a button that when tapped lets the user add a new shipping address."
                )
            )
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .linkSurfacePrimary

            let stackView = UIStackView(arrangedSubviews: [
                addressSection.view,
                errorView,
                saveButton,
            ])
            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.directionalLayoutMargins = LinkUI.contentMargins
            stackView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addAndPinSubview(stackView, insets: .insets(bottom: LinkUI.bottomInset))

            updateSaveButton()
        }

        private func updateSaveButton() {
            saveButton.update(status: addressSection.validationState.isValid ? .enabled : .disabled)
        }

        private func updateErrorLabel(for error: Error?) {
            errorView.text = error?.nonGenericDescription
            errorView.setHiddenIfNecessary(error == nil)
        }

        private func saveShippingAddress() {
            updateErrorLabel(for: nil)

            let addressDetails = addressSection.addressDetails
            let address = STPPaymentMethodAddress()
            address.line1 = addressDetails.address.line1
            address.line2 = addressDetails.address.line2
            address.city = addressDetails.address.city
            address.state = addressDetails.address.state
            address.postalCode = addressDetails.address.postalCode
            address.country = addressDetails.address.country

            addressSection.view.endEditing(true)
            saveButton.update(status: .processing)
            setUserInteractionEnabled(false)

            linkAccount.createShippingAddress(name: addressDetails.name, address: address) { [weak self] result in
                guard let self else {
                    return
                }

                switch result {
                case .success(let shippingAddress):
                    self.saveButton.update(status: .succeeded, callToAction: nil, animated: true) {
                        self.setUserInteractionEnabled(true)
                        self.delegate?.didAdd(shippingAddress: shippingAddress)
                        _ = self.bottomSheetController?.popContentViewController()
                    }
                case .failure(let error):
                    self.updateErrorLabel(for: error)
                    self.saveButton.update(status: .enabled)
                    self.setUserInteractionEnabled(true)
                }
            }
        }
    }

}

// MARK: - ElementDelegate

extension PayWithLinkViewController.AddShippingAddressViewController: ElementDelegate {

    func didUpdate(element: Element) {
        updateErrorLabel(for: nil)
        updateSaveButton()
    }

    func continueToNextField(element: Element) {
        updateSaveButton()
    }

}
