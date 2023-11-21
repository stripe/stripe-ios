//
//  UpdateCardViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 10/27/23.
//
import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol UpdateCardViewControllerDelegate: AnyObject {
    func didRemove(paymentOptionCell: SavedPaymentMethodCollectionView.PaymentOptionCell)
    func didUpdate(paymentOptionCell: SavedPaymentMethodCollectionView.PaymentOptionCell,
                   updateParams: STPPaymentMethodUpdateParams) async throws
}

/// For internal SDK use only
@objc(STP_Internal_UpdateCardViewController)
final class UpdateCardViewController: UIViewController {
    private let appearance: PaymentSheet.Appearance
    private let paymentMethod: STPPaymentMethod
    private let paymentOptionCell: SavedPaymentMethodCollectionView.PaymentOptionCell
    private let removeSavedPaymentMethodMessage: String?

    weak var delegate: UpdateCardViewControllerDelegate?

    // MARK: Navigation bar
    internal lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: false,
                                        appearance: appearance)
        navBar.delegate = self
        navBar.setStyle(.back)
        return navBar
    }()

    // MARK: Views
    lazy var formStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerLabel, cardSection.view, updateButton, deleteButton])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.setCustomSpacing(PaymentSheetUI.defaultPadding - 4, after: headerLabel) // custom spacing from figma
        stackView.setCustomSpacing(32, after: cardSection.view) // custom spacing from figma
        stackView.setCustomSpacing(stackView.spacing / 2, after: updateButton)
        stackView.layoutMargins.bottom = PaymentSheetUI.defaultPadding * 1.1
        return stackView
    }()

    private lazy var headerLabel: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: appearance)
        label.text = .Localized.update_card
        return label
    }()

    private lazy var updateButton: ConfirmButton = {
        return ConfirmButton(state: .disabled, callToAction: .custom(title: .Localized.update_card), appearance: appearance, didTap: {  [weak self] in
            Task {
                await self?.updateCard()
            }
        })
    }()

    private lazy var deleteButton: ConfirmButton = {
        var apperanceCopy = appearance
        apperanceCopy.colors.primary = appearance.colors.background
        apperanceCopy.primaryButton.textColor = appearance.colors.danger
        apperanceCopy.primaryButton.borderColor = .clear
        apperanceCopy.primaryButton.shadow = .init(color: .clear, opacity: 0.0, offset: .zero, radius: 0.0)
        return ConfirmButton(callToAction: .custom(title: .Localized.remove_card), appearance: apperanceCopy) { [weak self] in
            self?.removeCard()
        }
    }()

    // MARK: Elements
    private lazy var panElement: TextFieldElement = {
        return TextFieldElement.LastFourConfiguration(lastFour: paymentMethod.card?.last4 ?? "", cardBrandDropDown: cardBrandDropDown).makeElement(theme: appearance.asElementsTheme)
    }()

    private lazy var cardBrandDropDown: DropdownFieldElement = {
        let cardBrands = paymentMethod.card?.networks?.available.map({ STPCard.brand(from: $0) }) ?? []
        let cardBrandDropDown = DropdownFieldElement.makeCardBrandDropdown(cardBrands: Set<STPCardBrand>(cardBrands), theme: appearance.asElementsTheme)

        // pre-select current card brand
        if let currentCardBrand = paymentMethod.card?.networks?.preferred?.toCardBrand,
           let indexToSelect = cardBrandDropDown.items.firstIndex(where: { $0.rawData == STPCardBrandUtilities.apiValue(from: currentCardBrand) }) {
            cardBrandDropDown.select(index: indexToSelect, shouldAutoAdvance: false)
        }

        return cardBrandDropDown
    }()

    private lazy var cardSection: SectionElement = {
        let allSubElements: [Element?] = [
            panElement, SectionElement.HiddenElement(cardBrandDropDown),
        ]

        let section = SectionElement(elements: allSubElements.compactMap { $0 }, theme: appearance.asElementsTheme)
        section.delegate = self
        return section
    }()

    // MARK: Overrides
    init(paymentOptionCell: SavedPaymentMethodCollectionView.PaymentOptionCell,
         paymentMethod: STPPaymentMethod,
         removeSavedPaymentMethodMessage: String?,
         appearance: PaymentSheet.Appearance) {
        self.paymentOptionCell = paymentOptionCell
        self.paymentMethod = paymentMethod
        self.removeSavedPaymentMethodMessage = removeSavedPaymentMethodMessage
        self.appearance = appearance

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // disable swipe to dismiss
        isModalInPresentation = true

        let stackView = UIStackView(arrangedSubviews: [formStackView])
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = appearance.colors.background
        view.backgroundColor = appearance.colors.background
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }

    // MARK: Private helpers
    private func dismiss() {
        guard let bottomVc = parent as? BottomSheetViewController else { return }
        _ = bottomVc.popContentViewController()
    }

    private func removeCard() {
        let alertController = UIAlertController.makeRemoveAlertController(paymentMethod: paymentMethod,
                                                                          removeSavedPaymentMethodMessage: removeSavedPaymentMethodMessage) { [weak self] in
            guard let self = self else { return }
            self.delegate?.didRemove(paymentOptionCell: self.paymentOptionCell)
            self.dismiss()
        }

        present(alertController, animated: true, completion: nil)
    }

    private func updateCard() async {
        guard let selectedBrand = cardBrandDropDown.selectedItem.rawData.toCardBrand, let delegate = delegate else { return }

        updateButton.update(state: .processing)

        // Create the update card params
        let cardParams = STPPaymentMethodCardParams()
        cardParams.networks = .init(preferred: STPCardBrandUtilities.apiValue(from: selectedBrand))
        let updateParams = STPPaymentMethodUpdateParams(card: cardParams, billingDetails: nil)

        // Make the API request to update the payment method
        do {
            try await delegate.didUpdate(paymentOptionCell: paymentOptionCell, updateParams: updateParams)
            updateButton.update(state: .succeeded, animated: true) { [weak self] in
                self?.dismiss()
            }
        } catch {
            // TODO(porter) Handle error
            updateButton.update(state: .enabled)
            print(error)
        }
    }

}

// MARK: BottomSheetContentViewController
extension UpdateCardViewController: BottomSheetContentViewController {

    var allowsDragToDismiss: Bool {
        return false
    }

    func didTapOrSwipeToDismiss() {
        // no-op
    }

    var requiresFullScreen: Bool {
        return false
    }
}

// MARK: SheetNavigationBarDelegate
extension UpdateCardViewController: SheetNavigationBarDelegate {

    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        dismiss()
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        dismiss()
    }

}

// MARK: ElementDelegate
extension UpdateCardViewController: ElementDelegate {
    func continueToNextField(element: Element) {
        // no-op
    }

    func didUpdate(element: Element) {
        let selectedBrand = cardBrandDropDown.selectedItem.rawData.toCardBrand
        let currentCardBrand = STPCard.brand(from: paymentMethod.card?.networks?.preferred ?? "")
        let shouldBeEnabled = selectedBrand != currentCardBrand && selectedBrand != .unknown
        updateButton.update(state: shouldBeEnabled ? .enabled : .disabled)
    }
}
