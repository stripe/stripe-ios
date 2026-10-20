//
//  LinkAgentWalletViewController-PaymentDetailsListViewController.swift
//  StripePaymentSheet
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

extension LinkAgentWalletViewController {

    /// Lists the cards in the customer's Link account so they can pick a different one or add a new one.
    final class PaymentDetailsListViewController: UIViewController {

        typealias AddCard = (STPPaymentMethodParams) async throws -> ConsumerPaymentDetails

        private let paymentDetails: [ConsumerPaymentDetails]
        private let selectedPaymentDetails: ConsumerPaymentDetails
        private let appearance: LinkAppearance?
        private let addCard: AddCard
        private let didSelect: (ConsumerPaymentDetails) -> Void

        private lazy var cells: [LinkPaymentMethodPicker.Cell] = paymentDetails.map { paymentDetails in
            let cell = LinkPaymentMethodPicker.Cell()
            cell.paymentMethod = paymentDetails
            cell.showsMenu = false
            cell.selectionIndicator = .checkmark
            if let primary = appearance?.colors?.primary {
                cell.checkmarkTintColor = primary
            }
            cell.isSelected = paymentDetails.stripeID == selectedPaymentDetails.stripeID
            cell.delegate = self
            return cell
        }

        private lazy var addCardRow: AddCardRow = {
            let row = AddCardRow()
            row.addTarget(self, action: #selector(didTapAddCard), for: .touchUpInside)
            return row
        }()

        private lazy var listView: UIStackView = {
            let listView = UIStackView(arrangedSubviews: cells + [addCardRow])
            listView.axis = .vertical
            listView.backgroundColor = .linkSurfaceSecondary
            listView.clipsToBounds = true
            if let cornerRadius = LinkUI.appearance.cornerRadius {
                listView.layer.cornerRadius = cornerRadius
            } else {
                listView.ios26_applyDefaultCornerConfiguration()
            }
            return listView
        }()

        /// - Parameters:
        ///   - paymentDetails: The cards to list.
        ///   - selectedPaymentDetails: The card to show as selected.
        ///   - appearance: Appearance overrides for the Link UI.
        ///   - addCard: Saves a new card to the customer's Link account and returns it.
        ///   - didSelect: Called with the card the customer picked or added, before the sheet dismisses.
        init(
            paymentDetails: [ConsumerPaymentDetails],
            selectedPaymentDetails: ConsumerPaymentDetails,
            appearance: LinkAppearance?,
            addCard: @escaping AddCard,
            didSelect: @escaping (ConsumerPaymentDetails) -> Void
        ) {
            self.paymentDetails = paymentDetails
            self.selectedPaymentDetails = selectedPaymentDetails
            self.appearance = appearance
            self.addCard = addCard
            self.didSelect = didSelect
            super.init(nibName: nil, bundle: nil)
            title = String.Localized.select_card
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(didTapCloseButton)
            )
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .linkSurfacePrimary

            let scrollView = UIScrollView()
            view.addAndPinSubview(scrollView)
            scrollView.addSubview(listView)
            listView.translatesAutoresizingMaskIntoConstraints = false

            let margins = LinkUI.contentMargins
            NSLayoutConstraint.activate([
                listView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: LinkUI.contentSpacing),
                listView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: margins.leading),
                listView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -margins.trailing),
                listView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -margins.bottom),
            ])

            // Match the height of the card rows.
            if let firstCell = cells.first {
                addCardRow.heightAnchor.constraint(equalTo: firstCell.heightAnchor).isActive = true
            }
        }

        @objc private func didTapCloseButton() {
            dismiss(animated: true)
        }

        @objc private func didTapAddCard() {
            let formViewController = AddCardFormViewController(appearance: appearance, addCard: addCard) { [weak self] card in
                self?.didSelect(card)
                self?.dismiss(animated: true)
            }
            navigationController?.pushViewController(formViewController, animated: true)

            // Make room for the keyboard.
            if let sheetPresentationController = navigationController?.sheetPresentationController {
                sheetPresentationController.animateChanges {
                    sheetPresentationController.selectedDetentIdentifier = .large
                }
            }
        }
    }
}

// MARK: - AddCardRow

extension LinkAgentWalletViewController.PaymentDetailsListViewController {

    /// A row below the cards that lets the customer add a new card.
    final class AddCardRow: UIControl {

        private let iconView: UIImageView = {
            let iconView = UIImageView(image: Image.pm_type_card_outlined.makeImage(template: true))
            iconView.tintColor = .linkIconPrimary
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false
            return iconView
        }()

        private let textLabel: UILabel = {
            let label = UILabel()
            label.text = String.Localized.add_card
            label.numberOfLines = 0
            label.textColor = .linkTextPrimary
            label.font = LinkUI.font(forTextStyle: .bodyEmphasized)
            label.adjustsFontForContentSizeCategory = true
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        override var isHighlighted: Bool {
            didSet {
                backgroundColor = isHighlighted ? .linkSurfaceTertiary : .clear
            }
        }

        init() {
            super.init(frame: .zero)
            isAccessibilityElement = true
            accessibilityTraits = .button
            accessibilityLabel = textLabel.text
            directionalLayoutMargins = LinkPaymentMethodPicker.Cell.Constants.margins

            addSubview(iconView)
            addSubview(textLabel)

            // Draw the icon at the card brand icons' size, centered in the same slot, and line up the text with the cells' labels.
            let iconContainerSideLength = LinkPaymentMethodPicker.CellContentView.iconContainerSideLength
            let iconSize = CardBrandView.targetIconSize
            let textLabelTopConstraint = textLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor)
            let textLabelBottomConstraint = textLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            // The list makes this row as tall as the card rows, so let that win over the label's natural height.
            textLabelTopConstraint.priority = .defaultHigh
            textLabelBottomConstraint.priority = .defaultHigh
            NSLayoutConstraint.activate([
                iconView.centerXAnchor.constraint(
                    equalTo: layoutMarginsGuide.leadingAnchor,
                    constant: iconContainerSideLength / 2
                ),
                iconView.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: iconSize.width),
                iconView.heightAnchor.constraint(equalToConstant: iconSize.height),

                textLabelTopConstraint,
                textLabelBottomConstraint,
                textLabel.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
                textLabel.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor),
                textLabel.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor),
                textLabel.leadingAnchor.constraint(
                    equalTo: layoutMarginsGuide.leadingAnchor,
                    constant: iconContainerSideLength + LinkPaymentMethodPicker.CellContentView.Constants.contentSpacing
                ),
                textLabel.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
            ])

            if LinkUI.useLiquidGlass {
                heightAnchor.constraint(greaterThanOrEqualToConstant: LinkUI.minimumItemHeightForLiquidGlass).isActive = true
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: - AddCardFormViewController

extension LinkAgentWalletViewController.PaymentDetailsListViewController {

    /// Collects a new card and saves it to the customer's Link account.
    final class AddCardFormViewController: UIViewController {

        private let appearance: LinkAppearance?
        private let addCard: AddCard
        private let didAddCard: (ConsumerPaymentDetails) -> Void
        private let theme: ElementsAppearance
        private var isProcessing = false

        private lazy var cardSectionElement: CardSectionElement = {
            let element = CardSectionElement(
                hostedSurface: .paymentSheet,
                theme: theme,
                analyticsHelper: nil,
                linkAppearance: appearance
            )
            element.delegate = self
            return element
        }()

        private lazy var errorLabel: UILabel = {
            let label = ElementsUI.makeErrorLabel(theme: theme)
            label.isHidden = true
            return label
        }()

        private lazy var confirmButton: ConfirmButton = .makeLinkButton(
            callToAction: .custom(title: String.Localized.add_card),
            showProcessingLabel: false,
            linkAppearance: appearance,
            didTapWhenDisabled: { [weak self] in
                self?.cardSectionElement.showAllValidationErrors()
            },
            didTap: { [weak self] in
                self?.didTapAddCard()
            }
        )

        private lazy var stackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [cardSectionElement.view, errorLabel])
            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.directionalLayoutMargins = LinkUI.contentMargins
            stackView.translatesAutoresizingMaskIntoConstraints = false
            return stackView
        }()

        /// Keeps the confirm button at the bottom of the sheet, above the keyboard.
        private lazy var buttonContainerView: UIView = {
            let containerView = UIView()
            containerView.addAndPinSubview(
                confirmButton,
                insets: .insets(
                    top: LinkUI.contentSpacing,
                    leading: LinkUI.contentMargins.leading,
                    bottom: LinkUI.contentMargins.bottom,
                    trailing: LinkUI.contentMargins.trailing
                )
            )
            containerView.translatesAutoresizingMaskIntoConstraints = false
            return containerView
        }()

        init(
            appearance: LinkAppearance?,
            addCard: @escaping AddCard,
            didAddCard: @escaping (ConsumerPaymentDetails) -> Void
        ) {
            self.appearance = appearance
            self.theme = LinkAgentWalletViewController.makeTheme(appearance: appearance)
            self.addCard = addCard
            self.didAddCard = didAddCard
            super.init(nibName: nil, bundle: nil)
            title = String.Localized.add_card
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .linkSurfacePrimary

            let scrollView = UIScrollView()
            #if !os(visionOS)
            scrollView.keyboardDismissMode = .onDrag
            #endif
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(scrollView)
            view.addSubview(buttonContainerView)
            scrollView.addSubview(stackView)

            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: buttonContainerView.topAnchor),

                buttonContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                buttonContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                buttonContainerView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

                stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: LinkUI.contentSpacing),
                stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            ])

            updateUI()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            _ = cardSectionElement.beginEditing()
        }

        private func didTapAddCard() {
            guard
                !isProcessing,
                let params = cardSectionElement.updateParams(params: IntentConfirmParams(type: .stripe(.card)))
            else {
                return
            }

            view.endEditing(true)
            updateError(nil)
            isProcessing = true
            updateUI()

            Task { @MainActor in
                do {
                    let card = try await addCard(params.paymentMethodParams)
                    confirmButton.update(status: .succeeded, animated: true) {
                        self.didAddCard(card)
                    }
                } catch {
                    isProcessing = false
                    updateError(error)
                    updateUI()
                }
            }
        }

        private func updateUI() {
            cardSectionElement.view.isUserInteractionEnabled = !isProcessing
            // Keep the customer on this screen while the card is saving.
            navigationItem.hidesBackButton = isProcessing
            navigationController?.isModalInPresentation = isProcessing

            let status: ConfirmButton.Status = {
                if isProcessing {
                    return .processing
                }
                return cardSectionElement.validationState.isValid ? .enabled : .disabled
            }()
            confirmButton.update(status: status, animated: true)
        }

        private func updateError(_ error: Error?) {
            errorLabel.text = error?.nonGenericDescription
            stackView.toggleArrangedSubview(errorLabel, shouldShow: error != nil, animated: true)
        }
    }
}

// MARK: - ElementDelegate

extension LinkAgentWalletViewController.PaymentDetailsListViewController.AddCardFormViewController: ElementDelegate {
    func didUpdate(element: Element) {
        updateUI()
    }

    func continueToNextField(element: Element) {
        // No-op
    }
}

// MARK: - LinkPaymentMethodPickerCellDelegate

extension LinkAgentWalletViewController.PaymentDetailsListViewController: LinkPaymentMethodPickerCellDelegate {
    func savedPaymentPickerCellDidSelect(_ cell: LinkPaymentMethodPicker.Cell) {
        guard let paymentMethod = cell.paymentMethod else {
            return
        }
        cells.forEach { $0.isSelected = $0 === cell }
        didSelect(paymentMethod)
        dismiss(animated: true)
    }

    func savedPaymentPickerCell(_ cell: LinkPaymentMethodPicker.Cell, didTapMenuButton button: UIButton) {
        // No-op: the menu is hidden.
    }

    func savedPaymentPickerCellMenuActions(
        for cell: LinkPaymentMethodPicker.Cell
    ) -> [PayWithLinkViewController.WalletViewController.Action]? {
        return nil
    }
}
