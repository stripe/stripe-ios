//
//  PayWithLinkViewController-AddShippingAddressViewController.swift
//  StripePaymentSheet
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PayWithLinkViewController {

    /// A form for creating a new shipping address, embedded in the Link bottom sheet navigation.
    final class AddShippingAddressViewController: BaseViewController {

        private let linkAccount: PaymentSheetLinkAccount
        private let viewModel: WalletViewModel
        private let onAddressCreated: (ShippingAddressesResponse.ShippingAddress) -> Void

        private lazy var theme: ElementsAppearance = {
            var theme = LinkUI.appearance.asElementsTheme
            if let primaryColor = viewModel.linkAppearance?.colors?.primary {
                theme.colors.primary = primaryColor
            }
            return theme
        }()

        private lazy var addressElement: AddressSectionElement = {
            let additionalFields = AddressSectionElement.AdditionalFields(
                name: .enabled(isOptional: false)
            )
            return AddressSectionElement(
                title: nil,
                countries: viewModel.allowedShippingCountries,
                defaults: .empty,
                defaultFieldsToCollect: .all,
                disableAutocomplete: true,
                additionalFields: additionalFields,
                theme: theme
            )
        }()

        private lazy var saveButton: ConfirmButton = .makeLinkButton(
            callToAction: .custom(
                title: STPLocalizedString(
                    "Save address",
                    "Button to save a new shipping address in the Link wallet."
                )
            ),
            showProcessingLabel: false,
            linkAppearance: viewModel.linkAppearance,
            didTapWhenDisabled: { [weak self] in
                self?.addressElement.showAllValidationErrors()
            }
        ) { [weak self] in
            self?.saveAddress()
        }

        private lazy var errorView: LinkHintMessageView = {
            let view = LinkHintMessageView(message: nil, style: .error)
            view.isHidden = true
            return view
        }()

        init(
            linkAccount: PaymentSheetLinkAccount,
            viewModel: WalletViewModel,
            onAddressCreated: @escaping (ShippingAddressesResponse.ShippingAddress) -> Void
        ) {
            self.linkAccount = linkAccount
            self.viewModel = viewModel
            self.onAddressCreated = onAddressCreated
            super.init(
                context: viewModel.context,
                navigationTitle: STPLocalizedString(
                    "Add address",
                    "Navigation title for the add shipping address screen."
                )
            )
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            addressElement.delegate = self

            let stackView = UIStackView(arrangedSubviews: [
                addressElement.view,
                errorView,
                saveButton,
            ])
            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.directionalLayoutMargins = LinkUI.contentMargins
            stackView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addAndPinSubview(stackView, insets: .insets(bottom: LinkUI.bottomInset))

            updateSaveButtonStatus()
        }

        private func updateSaveButtonStatus() {
            saveButton.update(status: addressElement.validationState.isValid ? .enabled : .disabled)
        }

        private func saveAddress() {
            let details = addressElement.addressDetails
            let params = CreateShippingAddressParams(
                name: details.name,
                line1: details.address.line1,
                line2: details.address.line2,
                locality: details.address.city,
                administrativeArea: details.address.state,
                postalCode: details.address.postalCode,
                countryCode: details.address.country
            )

            view.endEditing(true)
            addressElement.view.isUserInteractionEnabled = false
            saveButton.update(status: .processing)
            coordinator?.allowSheetDismissal(false)

            linkAccount.createShippingAddress(params: params) { [weak self] result in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.coordinator?.allowSheetDismissal(true)
                    switch result {
                    case .success(let address):
                        self.saveButton.update(status: .succeeded, callToAction: nil, animated: true) {
                            self.onAddressCreated(address)
                        }
                    case .failure(let error):
                        self.errorView.text = error.nonGenericDescription
                        self.errorView.isHidden = false
                        self.addressElement.view.isUserInteractionEnabled = true
                        self.saveButton.update(status: .enabled)
                    }
                }
            }
        }
    }
}

extension PayWithLinkViewController.AddShippingAddressViewController: ElementDelegate {
    func didUpdate(element: Element) {
        errorView.isHidden = true
        updateSaveButtonStatus()
    }

    func continueToNextField(element: Element) {
        updateSaveButtonStatus()
    }
}
