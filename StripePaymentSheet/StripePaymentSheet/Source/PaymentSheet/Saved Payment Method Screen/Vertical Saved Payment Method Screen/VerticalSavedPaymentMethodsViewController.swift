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
    /// Handles the selection of a payment method from the list or the modification of the list such as the removal or update of payment methods.
    ///
    /// - Parameters:
    ///    - viewController: The `VerticalSavedPaymentMethodsViewController` that completed it's selection
    ///    - selectedPaymentMethod: The selected method of payment, if any.
    ///    - latestPaymentMethods: The most recent up-to-date list of payment methods, with the selected (if any) payment method at the front of the list.
    func didComplete(viewController: VerticalSavedPaymentMethodsViewController,
                     with selectedPaymentMethod: STPPaymentMethod?,
                     latestPaymentMethods: [STPPaymentMethod])

    /// Notifies the delegate it should close the entire sheet it is presented in
    func shouldClose()
}

/// A view controller that shows a list of saved payment methods in a vertical orientation
class VerticalSavedPaymentMethodsViewController: UIViewController {

    // MARK: Private properties
    private let configuration: PaymentSheet.Configuration
    private let elementsSession: STPElementsSession
    private let paymentMethodRemove: Bool
    private let isCBCEligible: Bool
    private let analyticsHelper: PaymentSheetAnalyticsHelper

    private var updateViewController: UpdateCardViewController?

    private var isEditingPaymentMethods: Bool = false {
        didSet {
            let additionalButtonTitle = isEditingPaymentMethods ? UIButton.doneButtonTitle : UIButton.editButtonTitle
            navigationBar.additionalButton.setTitle(additionalButtonTitle, for: .normal)
            headerLabel.text = headerText

            // If we are entering edit mode, put all buttons in an edit state, otherwise put back in their previous state
            if isEditingPaymentMethods {
                paymentMethodRows.forEach { $0.state = .editing(allowsRemoval: canRemovePaymentMethods,
                                                                allowsUpdating: $0.paymentMethod.isCoBrandedCard && isCBCEligible) }
            } else if oldValue {
                // If we are exiting edit mode restore previous selected states
                paymentMethodRows.forEach { $0.state = $0.previousSelectedState }
                navigationBar.setStyle(.back(showAdditionalButton: canEdit)) // Hide edit button if needed

                // If we are exiting edit mode and there is only one payment method left which can't be removed, select it and dismiss
                if paymentMethodRows.count == 1, let firstButton = paymentMethodRows.first {
                    firstButton.state = .selected
                    completeSelection(afterDelay: 0.3)
                }
            }
        }
    }

    private var headerText: String {
        if isRemoveOnlyMode {
            return .Localized.remove_payment_method
        }

        if isEditingPaymentMethods {
            return paymentMethods.count == 1 ?  .Localized.manage_payment_method : .Localized.manage_payment_methods
        }

        let nonCardPaymentMethods = paymentMethods.filter({ $0.type != .card })
        return nonCardPaymentMethods.isEmpty ? .Localized.select_card : .Localized.select_payment_method
    }

    var canRemovePaymentMethods: Bool {
        // Can remove a payment method if we have more than one payment method or if we have one payment method and `allowsRemovalOfLastSavedPaymentMethod` is true AND paymentMethodRemove is true
        return (paymentMethodRows.count > 1 ? true : configuration.allowsRemovalOfLastSavedPaymentMethod) && paymentMethodRemove
    }

    var canEdit: Bool {
        // We can edit if there are removable or editable payment methods and we are not in remove only mode
        return (canRemovePaymentMethods || (hasCoBrandedCards && isCBCEligible)) && !isRemoveOnlyMode
    }

    private var selectedPaymentMethod: STPPaymentMethod? {
        return paymentMethodRows.first { $0.isSelected }?.paymentMethod
    }

    private var paymentMethods: [STPPaymentMethod] {
        return paymentMethodRows.map { $0.paymentMethod }
    }

    private var hasCoBrandedCards: Bool {
        return !paymentMethods.filter { $0.isCoBrandedCard }.isEmpty
    }

    private lazy var savedPaymentMethodManager: SavedPaymentMethodManager = {
        SavedPaymentMethodManager(configuration: configuration, elementsSession: elementsSession)
    }()

    /// Determines if the we should operate in "Remove Only Mode". This mode is enabled under the following conditions:
    /// - There is exactly one payment method available at init time.
    /// - The single available payment method is not a co-branded card.
    /// In this mode, the user can only delete the payment method; updating or selecting other payment methods is disabled.
    let isRemoveOnlyMode: Bool

    // MARK: Internal properties
    weak var delegate: VerticalSavedPaymentMethodsViewControllerDelegate?

    // MARK: - UI properties

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.setStyle(.back(showAdditionalButton: canEdit))
        navBar.delegate = self
        navBar.additionalButton.configureCommonEditButton(isEditingPaymentMethods: isEditingPaymentMethods, appearance: configuration.appearance)
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
        let spacerView = UIView(frame: .zero)
        spacerView.translatesAutoresizingMaskIntoConstraints = false

        let heightConstraint = spacerView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = UILayoutPriority(rawValue: 1)
        heightConstraint.isActive = true

        let stackView = UIStackView(arrangedSubviews: [headerLabel] + paymentMethodRows + [spacerView])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.setCustomSpacing(16, after: headerLabel)
        if let lastPaymentMethodRow = paymentMethodRows.last {
            stackView.setCustomSpacing(0, after: lastPaymentMethodRow)
        }
        return stackView
    }()

    private var paymentMethodRows: [SavedPaymentMethodRowButton] = []

    init(
        configuration: PaymentSheet.Configuration,
        selectedPaymentMethod: STPPaymentMethod?,
        paymentMethods: [STPPaymentMethod],
        elementsSession: STPElementsSession,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) {
        self.configuration = configuration
        self.elementsSession = elementsSession
        self.paymentMethodRemove = elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()
        self.isCBCEligible = elementsSession.isCardBrandChoiceEligible
        self.analyticsHelper = analyticsHelper
        // Put in remove only mode and don't show the option to update PMs if:
        // 1. We only have 1 payment method
        // 2. The customer can't update the card brand 
        self.isRemoveOnlyMode = paymentMethods.count == 1 && (!paymentMethods[0].isCoBrandedCard || !isCBCEligible)
        super.init(nibName: nil, bundle: nil)
        self.paymentMethodRows = buildPaymentMethodRows(paymentMethods: paymentMethods)
        setInitialState(selectedPaymentMethod: selectedPaymentMethod)
    }

    private func buildPaymentMethodRows(paymentMethods: [STPPaymentMethod]) -> [SavedPaymentMethodRowButton] {
        return paymentMethods.map { paymentMethod in
            let button = SavedPaymentMethodRowButton(paymentMethod: paymentMethod,
                                                appearance: configuration.appearance)
            button.delegate = self
            return button
        }
    }

    private func setInitialState(selectedPaymentMethod: STPPaymentMethod?) {
        paymentMethodRows.first { $0.paymentMethod.stripeId == selectedPaymentMethod?.stripeId }?.state = .selected
        if isRemoveOnlyMode {
            paymentMethodRows.first?.state = .editing(allowsRemoval: canRemovePaymentMethods, allowsUpdating: false)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background
        configuration.style.configure(self)

        view.addAndPinSubview(stackView, insets: PaymentSheetUI.defaultSheetMargins)

        // Add a height constraint to the view to ensure a minimum height of 200
        let minHeightConstraint = view.heightAnchor.constraint(greaterThanOrEqualToConstant: 200 - SheetNavigationBar.height)
        minHeightConstraint.priority = .defaultHigh
        minHeightConstraint.isActive = true
    }

    @objc func didSelectEditSavedPaymentMethodsButton() {
        isEditingPaymentMethods = !isEditingPaymentMethods
    }

    private func remove(paymentMethod: STPPaymentMethod) {
        guard let button = paymentMethodRows.first(where: { $0.paymentMethod.stripeId == paymentMethod.stripeId }) else { return }

        // Detach the payment method from the customer
        savedPaymentMethodManager.detach(paymentMethod: paymentMethod)

        // Remove the payment method row button
        paymentMethodRows.removeAll { $0.paymentMethod.stripeId == paymentMethod.stripeId }
        stackView.removeArrangedSubview(button, animated: true)

        // Update the editing state if needed
        isEditingPaymentMethods = canEdit

        // If we deleted the last payment method kick back out to the main screen
        if paymentMethodRows.isEmpty {
            completeSelection()
        }
    }

    private func completeSelection(afterDelay: TimeInterval = 0.0) {
        // Note this dispatch async gives a brief delay, even when `afterDelay` is 0
        DispatchQueue.main.asyncAfter(deadline: .now() + afterDelay) { [weak self] in
            guard let self = self else { return }
            // Edge-case: Dismiss `UpdateViewController` if presented, this can occur if `completeSelection` is called before `UpdateViewController` is popped when we remove the last payment method via the `UpdateViewController`
            _ = self.updateViewController?.bottomSheetController?.popContentViewController()

            var latestPaymentMethods = self.paymentMethods
            // Move selected payment method to the front of `latestPaymentMethods`
            if let selectedPaymentMethod = self.selectedPaymentMethod {
                latestPaymentMethods.remove(selectedPaymentMethod)
                latestPaymentMethods.insert(selectedPaymentMethod, at: 0)
            }
            self.delegate?.didComplete(viewController: self, with: self.selectedPaymentMethod, latestPaymentMethods: latestPaymentMethods)
        }
    }
}

// MARK: - BottomSheetContentViewController
extension VerticalSavedPaymentMethodsViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        return true
    }

    func didTapOrSwipeToDismiss() {
        delegate?.shouldClose()
    }

    var requiresFullScreen: Bool {
        return false
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
extension VerticalSavedPaymentMethodsViewController: SavedPaymentMethodRowButtonDelegate {

    func didSelectButton(_ button: SavedPaymentMethodRowButton, with paymentMethod: STPPaymentMethod) {
        analyticsHelper.logSavedPMScreenOptionSelected(option: .saved(paymentMethod: paymentMethod))
        // Set payment method as default
        CustomerPaymentOption.setDefaultPaymentMethod(
            .stripeId(paymentMethod.stripeId),
            forCustomer: configuration.customer?.id
        )

        // Deselect previous button
        paymentMethodRows.first { $0 != button && $0.isSelected }?.state = .unselected

        // Disable interaction to prevent double selecting or entering edit mode since we will be dismissing soon
        self.view.isUserInteractionEnabled = false
        self.navigationBar.isUserInteractionEnabled = false

        self.completeSelection()
    }

    func didSelectRemoveButton(_ button: SavedPaymentMethodRowButton, with paymentMethod: STPPaymentMethod) {
        let alertController = UIAlertController.makeRemoveAlertController(paymentMethod: paymentMethod,
                                                                          removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage) { [weak self] in
            guard let self else { return }
            self.remove(paymentMethod: paymentMethod)
        }

        present(alertController, animated: true, completion: nil)
    }

    func didSelectUpdateButton(_ button: SavedPaymentMethodRowButton, with paymentMethod: STPPaymentMethod) {
        let updateViewController = UpdateCardViewController(paymentMethod: paymentMethod,
                                                            removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage,
                                                            appearance: configuration.appearance,
                                                            hostedSurface: .paymentSheet,
                                                            canRemoveCard: canRemovePaymentMethods,
                                                            isTestMode: configuration.apiClient.isTestmode)

        updateViewController.delegate = self
        self.updateViewController = updateViewController
        self.bottomSheetController?.pushContentViewController(updateViewController)
    }
}

// MARK: - UpdateCardViewControllerDelegate
extension VerticalSavedPaymentMethodsViewController: UpdateCardViewControllerDelegate {
    func didRemove(viewController: UpdateCardViewController, paymentMethod: STPPaymentMethod) {
        remove(paymentMethod: paymentMethod)
       _ = viewController.bottomSheetController?.popContentViewController()
    }

    func didUpdate(viewController: UpdateCardViewController, paymentMethod: STPPaymentMethod, updateParams: STPPaymentMethodUpdateParams) async throws {
        // Update the payment method
        let updatedPaymentMethod = try await savedPaymentMethodManager.update(paymentMethod: paymentMethod, with: updateParams)

        replace(paymentMethod: paymentMethod, with: updatedPaymentMethod)
        _ = viewController.bottomSheetController?.popContentViewController()
    }

    private func replace(paymentMethod: STPPaymentMethod, with updatedPaymentMethod: STPPaymentMethod) {
        guard let oldButton = paymentMethodRows.first(where: { $0.paymentMethod.stripeId == paymentMethod.stripeId }),
              let oldButtonModelIndex = paymentMethodRows.firstIndex(of: oldButton),
              let oldButtonViewIndex = stackView.arrangedSubviews.firstIndex(of: oldButton) else {
            stpAssertionFailure("Unable to retrieve the original button/payment method for replacement.")
            return
        }

        // Create the new button
        let newButton = SavedPaymentMethodRowButton(paymentMethod: updatedPaymentMethod, appearance: configuration.appearance)
        newButton.delegate = self
        newButton.previousSelectedState = oldButton.previousSelectedState
        newButton.state = oldButton.state

        // Replace the old button with the new button in the model
        paymentMethodRows[oldButtonModelIndex] = newButton

        // Replace the old button with the new button in the stack view
        oldButton.removeFromSuperview()
        stackView.insertArrangedSubview(newButton, at: oldButtonViewIndex)
    }

}
