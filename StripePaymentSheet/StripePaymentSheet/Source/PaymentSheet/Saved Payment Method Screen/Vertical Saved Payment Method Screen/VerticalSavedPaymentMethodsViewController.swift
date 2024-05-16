//
//  VerticalSavedPaymentMethodsViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol VerticalSavedPaymentMethodsViewControllerDelegate: AnyObject {
    func didComplete(with selectedPaymentMethod: STPPaymentMethod?, latestPaymentMethods: [STPPaymentMethod])
}

/// A view controller that shows a list of saved payment methods in a vertical orientation
class VerticalSavedPaymentMethodsViewController: UIViewController {

    // MARK: Private properties
    private let configuration: PaymentSheet.Configuration

    private var isEditingPaymentMethods: Bool = false {
        didSet {
            let additionalButtonTitle = isEditingPaymentMethods ? UIButton.doneButtonTitle : UIButton.editButtonTitle
            navigationBar.additionalButton.setTitle(additionalButtonTitle, for: .normal)
            headerLabel.text = headerText

            // If we are entering edit mode, put all buttons in an edit state, otherwise put back in their previous state
            if isEditingPaymentMethods {
                paymentMethodRows.forEach { $0.state = .editing(allowsRemoval: canRemovePaymentMethods,
                                                                allowsUpdating: $0.paymentMethod.isCoBrandedCard) }
            } else {
                paymentMethodRows.forEach { $0.state = $0.previousState }
                navigationBar.setStyle(.back(showAdditionalButton: canEdit)) // Hide edit button if needed
            }
        }
    }

    private var headerText: String {
        if isEditingPaymentMethods {
            return .Localized.manage_payment_methods
        }

        let nonCardPaymentMethods = paymentMethodRows.filter({ $0.paymentMethod.type != .card })
        return nonCardPaymentMethods.isEmpty ? .Localized.select_card : .Localized.select_payment_method
    }

    var canRemovePaymentMethods: Bool {
        // Can remove a payment method if we have more than one payment method or if we have one payment method and `allowsRemovalOfLastSavedPaymentMethod` is true
        return paymentMethodRows.count > 1 ? true : configuration.allowsRemovalOfLastSavedPaymentMethod
    }

    var canEdit: Bool {
        let hasCoBrandedCards = !paymentMethodRows.filter { $0.paymentMethod.isCoBrandedCard }.isEmpty
        // We can edit if there are removable or editable payment methods
        return canRemovePaymentMethods || hasCoBrandedCards
    }

    private var selectedPaymentMethod: STPPaymentMethod? {
        return paymentMethodRows.first { $0.isSelected }?.paymentMethod
    }

    private var paymentMethods: [STPPaymentMethod] {
        return paymentMethodRows.map { $0.paymentMethod }
    }

    // MARK: Internal properties
    weak var delegate: VerticalSavedPaymentMethodsViewControllerDelegate?

    // MARK: - UI properties

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.setStyle(.back(showAdditionalButton: canEdit))
        navBar.delegate = self
        navBar.additionalButton.configureCommonEditButton(isEditingPaymentMethods: isEditingPaymentMethods)
        // TODO(porter) Read color from new secondary action color from appearance
        navBar.additionalButton.setTitleColor(configuration.appearance.colors.primary, for: .normal)
        navBar.additionalButton.setTitleColor(configuration.appearance.colors.primary.disabledColor, for: .disabled)
        navBar.additionalButton.addTarget(self, action: #selector(didSelectEditSavedPaymentMethodsButton), for: .touchUpInside)
        return navBar
    }()

    private lazy var headerLabel: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        label.text = headerText
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerLabel] + paymentMethodRows)
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.setCustomSpacing(16, after: headerLabel)
        return stackView
    }()

    private var paymentMethodRows: [PaymentMethodRowButton] = []

    init(configuration: PaymentSheet.Configuration, selectedPaymentMethod: STPPaymentMethod?, paymentMethods: [STPPaymentMethod]) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        self.paymentMethodRows = buildPaymentMethodRows(paymentMethods: paymentMethods)
        // Select `selectedPaymentMethod` or the first row if selectedPaymentMethod is nil
        (paymentMethodRows.first { $0.paymentMethod.stripeId == selectedPaymentMethod?.stripeId } ?? paymentMethodRows.first)?.state = .selected
    }

    private func buildPaymentMethodRows(paymentMethods: [STPPaymentMethod]) -> [PaymentMethodRowButton] {
        return paymentMethods.map { paymentMethod in
            let button = PaymentMethodRowButton(paymentMethod: paymentMethod,
                                                appearance: configuration.appearance)
            button.delegate = self
            return button
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background
        configuration.style.configure(self)
        // TODO(porter) Pipe in selected payment method, default to selecting first for now
        paymentMethodRows.first?.state = .selected
        view.addAndPinSubview(stackView, insets: PaymentSheetUI.defaultSheetMargins)
    }

    @objc func didSelectEditSavedPaymentMethodsButton() {
        isEditingPaymentMethods = !isEditingPaymentMethods
    }

    private func remove(paymentMethod: STPPaymentMethod) {
        guard let button = paymentMethodRows.first(where: { $0.paymentMethod.stripeId == paymentMethod.stripeId }),
                let ephemeralKeySecret = configuration.customer?.ephemeralKeySecret else { return }

        // Detach the payment method from the customer
        let manager = SavedPaymentMethodManager(configuration: configuration)
        manager.detach(paymentMethod: paymentMethod, using: ephemeralKeySecret)

        // Remove the payment method row button
        paymentMethodRows.removeAll { button === $0 }
        stackView.removeArrangedSubview(button, animated: true)

        // If we deleted the last payment method kick back out to the main screen
        if self.paymentMethodRows.isEmpty {
            completeSelection()
        } else if canEdit {
            // We can still edit, update the accessory buttons on the rows if needed
            paymentMethodRows.forEach { $0.state = .editing(allowsRemoval: canRemovePaymentMethods,
                                                            allowsUpdating: $0.paymentMethod.isCoBrandedCard) }
        } else {
            // If we can no longer edit, exit edit mode and hide edit button
            isEditingPaymentMethods = false
        }
    }

    private func completeSelection() {
        _ = self.bottomSheetController?.popContentViewController()
        self.delegate?.didComplete(with: selectedPaymentMethod, latestPaymentMethods: paymentMethods)
    }
}

// MARK: - BottomSheetContentViewController
extension VerticalSavedPaymentMethodsViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        return true
    }

    func didTapOrSwipeToDismiss() {
        dismiss(animated: true)
    }

    var requiresFullScreen: Bool {
        return false
    }

    func didFinishAnimatingHeight() {
        // no-op
    }
}

// MARK: - SheetNavigationBarDelegate
extension VerticalSavedPaymentMethodsViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        // no-op we are in 'back' style mode
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        completeSelection()
    }
}

// MARK: - PaymentMethodRowButtonDelegate
extension VerticalSavedPaymentMethodsViewController: PaymentMethodRowButtonDelegate {

    func didSelectButton(_ button: PaymentMethodRowButton, with paymentMethod: STPPaymentMethod) {
        // Deselect previous button        
        paymentMethodRows.first { $0 != button && $0.isSelected }?.state = .unselected

        // Disable interaction to prevent double selecting or entering edit mode since we will be dismissing soon
        self.view.isUserInteractionEnabled = false
        self.navigationBar.isUserInteractionEnabled = false

        // Give time for new selected row to show it has been selected before dismissing
        // Makes UX feel a little nicer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.completeSelection()
        }
    }

    func didSelectRemoveButton(_ button: PaymentMethodRowButton, with paymentMethod: STPPaymentMethod) {
        let alertController = UIAlertController.makeRemoveAlertController(paymentMethod: paymentMethod,
                                                                          removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage) { [weak self] in
            guard let self = self else { return }
            self.remove(paymentMethod: paymentMethod)
        }

        present(alertController, animated: true, completion: nil)
    }

    func didSelectUpdateButton(_ button: PaymentMethodRowButton, with paymentMethod: STPPaymentMethod) {
        print("Edit payment method with id: \(paymentMethod.stripeId)")
    }
}
