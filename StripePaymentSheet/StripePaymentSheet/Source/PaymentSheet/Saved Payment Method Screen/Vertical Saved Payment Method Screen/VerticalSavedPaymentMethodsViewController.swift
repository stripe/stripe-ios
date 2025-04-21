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

@MainActor
protocol VerticalSavedPaymentMethodsViewControllerDelegate: AnyObject {
    /// Handles the selection of a payment method from the list or the modification of the list such as the removal or update of payment methods.
    ///
    /// - Parameters:
    ///    - viewController: The `VerticalSavedPaymentMethodsViewController` that completed its selection
    ///    - selectedPaymentMethod: The selected method of payment, if any.
    ///    - latestPaymentMethods: The most recent up-to-date list of payment methods, with the selected (if any) payment method at the front of the list.
    ///    - didTapToDismiss: Whether or not the customer tapped outside the sheet to dismiss it.
    ///    - defaultPaymentMethod: The default payment method at the time the view controller completed its selection
    func didComplete(
        viewController: VerticalSavedPaymentMethodsViewController,
        with selectedPaymentMethod: STPPaymentMethod?,
        latestPaymentMethods: [STPPaymentMethod],
        didTapToDismiss: Bool,
        defaultPaymentMethod: STPPaymentMethod?
    )
}

/// A view controller that shows a list of saved payment methods in a vertical orientation
class VerticalSavedPaymentMethodsViewController: UIViewController {

    // MARK: Private properties
    private let configuration: PaymentElementConfiguration
    private let elementsSession: STPElementsSession
    private let paymentMethodRemove: Bool
    private let paymentMethodRemoveLast: Bool
    private let paymentMethodSetAsDefault: Bool
    private let paymentMethodUpdate: Bool
    private let isCBCEligible: Bool
    private let analyticsHelper: PaymentSheetAnalyticsHelper

    private var updateViewController: UpdatePaymentMethodViewController?
    private var defaultPaymentMethod: STPPaymentMethod?

    private var isEditingPaymentMethods: Bool = false {
        didSet {
            let additionalButtonTitle = isEditingPaymentMethods ? UIButton.doneButtonTitle : UIButton.editButtonTitle
            navigationBar.additionalButton.setTitle(additionalButtonTitle, for: .normal)
            // Update header text unless we removed the last pm and we're getting kicked out to the main screen
            if !paymentMethodRows.isEmpty {
                headerLabel.text = headerText
            }

            // If we are entering edit mode, put all buttons in an edit state, otherwise put back in their previous state
            if isEditingPaymentMethods {
                paymentMethodRows.forEach {
                    let allowsRemoval = canRemovePaymentMethods
                    let paymentMethodType = $0.paymentMethod.type
                    let allowsUpdating = PaymentSheet.supportedSavedPaymentMethods.contains { type in paymentMethodType == type }
                    $0.state = .editing(allowsRemoval: allowsRemoval,
                                        allowsUpdating: allowsUpdating)
                }
            } else if oldValue {
                // If we are exiting edit mode restore previous selected states
                paymentMethodRows.forEach { $0.state = $0.previousSelectedState }
                navigationBar.setStyle(navigationBarStyle())

                // If we are exiting edit mode and there is only one payment method left which can't be removed, select it and dismiss
                if paymentMethodRows.count == 1, let firstButton = paymentMethodRows.first {
                    firstButton.state = .selected
                    complete(afterDelay: 0.3)
                }
            }
        }
    }

    private var headerText: String {
        let nonCardPaymentMethods = paymentMethods.filter({ $0.type != .card })
        let hasOnlyCards = nonCardPaymentMethods.isEmpty
        if isEditingPaymentMethods {
            if hasOnlyCards {
                return paymentMethods.count == 1 ?  .Localized.manage_card : .Localized.manage_cards
            }
            return paymentMethods.count == 1 ?  .Localized.manage_payment_method : .Localized.manage_payment_methods
        }
        return hasOnlyCards ? .Localized.select_card : .Localized.select_payment_method
    }

    var canRemovePaymentMethods: Bool {
        // Can remove a payment method if we have more than one payment method or if we have one payment method and `allowsRemovalOfLastSavedPaymentMethod` is true AND paymentMethodRemove is true
        return (paymentMethodRows.count > 1 ? true : paymentMethodRemoveLast) && paymentMethodRemove
    }

    var canEditPaymentMethods: Bool {
        return (hasCoBrandedCards && isCBCEligible) || paymentMethodUpdate
    }

    /// Indicates whether the chevron should be shown
    /// True if any saved payment methods can be removed or edited
    var canRemoveOrEdit: Bool {
        let hasSupportedSavedPaymentMethods = paymentMethods.allSatisfy { PaymentSheet.supportedSavedPaymentMethods.contains($0.type) }
        guard hasSupportedSavedPaymentMethods else {
            fatalError("Saved payment methods contain unsupported payment methods.")
        }
        return paymentMethodSetAsDefault || canRemovePaymentMethods || canEditPaymentMethods
    }

    private var selectedPaymentMethod: STPPaymentMethod? {
        return paymentMethodRows.first { $0.isSelected }?.paymentMethod
    }

    private var previousSelectedPaymentMethod: STPPaymentMethod? {
        return paymentMethodRows.first { $0.previousSelectedState == .selected }?.paymentMethod
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

    // MARK: Internal properties
    weak var delegate: VerticalSavedPaymentMethodsViewControllerDelegate?

    // MARK: - UI properties

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.setStyle(navigationBarStyle())
        navBar.delegate = self
        navBar.additionalButton.configureCommonEditButton(isEditingPaymentMethods: isEditingPaymentMethods, appearance: configuration.appearance)
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
        configuration: PaymentElementConfiguration,
        selectedPaymentMethod: STPPaymentMethod?,
        paymentMethods: [STPPaymentMethod],
        elementsSession: STPElementsSession,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        defaultPaymentMethod: STPPaymentMethod?
    ) {
        self.configuration = configuration
        self.elementsSession = elementsSession
        self.defaultPaymentMethod = defaultPaymentMethod
        self.paymentMethodRemove = elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()
        self.paymentMethodRemoveLast = elementsSession.paymentMethodRemoveLast(configuration: configuration)
        self.paymentMethodUpdate = elementsSession.paymentMethodUpdateForPaymentSheet
        self.paymentMethodSetAsDefault = elementsSession.paymentMethodSetAsDefaultForPaymentSheet
        self.isCBCEligible = elementsSession.isCardBrandChoiceEligible
        self.analyticsHelper = analyticsHelper
        super.init(nibName: nil, bundle: nil)
        self.paymentMethodRows = buildPaymentMethodRows(paymentMethods: paymentMethods)
        setInitialState(selectedPaymentMethod: selectedPaymentMethod)
    }

    private func isDefaultPaymentMethod(paymentMethodId: String) -> Bool {
        guard paymentMethodSetAsDefault, let defaultPaymentMethod else { return false }
        return paymentMethodId == defaultPaymentMethod.stripeId
    }

    private func buildPaymentMethodRows(paymentMethods: [STPPaymentMethod]) -> [SavedPaymentMethodRowButton] {
        return paymentMethods.map { paymentMethod in
            let button = SavedPaymentMethodRowButton(paymentMethod: paymentMethod,
                                                     appearance: configuration.appearance,
                                                     showDefaultPMBadge: isDefaultPaymentMethod(paymentMethodId: paymentMethod.stripeId))
            button.delegate = self
            return button
        }
    }

    private func setInitialState(selectedPaymentMethod: STPPaymentMethod?) {
        paymentMethodRows.first { $0.paymentMethod.stripeId == selectedPaymentMethod?.stripeId }?.state = .selected
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

    private func navigationBarStyle() -> SheetNavigationBar.Style {
        if let bottomSheet = self.bottomSheetController,
           bottomSheet.contentStack.count > 1 {
            return .back(showAdditionalButton: canRemoveOrEdit)
        } else {
            return .close(showAdditionalButton: canRemoveOrEdit)
        }
    }

    @objc func didSelectEditSavedPaymentMethodsButton() {
        isEditingPaymentMethods = !isEditingPaymentMethods
    }

    private func remove(paymentMethod: STPPaymentMethod) {
        guard let button = paymentMethodRows.first(where: { $0.paymentMethod.stripeId == paymentMethod.stripeId }) else { return }

        // Detach the payment method from the customer
        savedPaymentMethodManager.detach(paymentMethod: paymentMethod)
        analyticsHelper.logSavedPaymentMethodRemoved(paymentMethod: paymentMethod)

        // Remove the payment method row button
        paymentMethodRows.removeAll { $0.paymentMethod.stripeId == paymentMethod.stripeId }
        stackView.removeArrangedSubview(button, animated: true)

        // Select the first payment method if nothing is selected anymore
        // Note: this isn't necessarily the desired behavior, but the next payment method *will* be selected if you cancel out of the sheet at this point, so it's better to be consistent until we change that.
        if selectedPaymentMethod == nil {
            paymentMethodRows.first?.state = .selected
        }

        // Update the editing state if needed
        isEditingPaymentMethods = canRemoveOrEdit

        // If we deleted the last payment method kick back out to the main screen
        if paymentMethodRows.isEmpty {
            complete(afterDelay: 0.3)
        }
    }

    private func complete(didTapToDismiss: Bool = false, afterDelay: TimeInterval = 0.0) {
        // Note this dispatch async gives a brief delay, even when `afterDelay` is 0
        DispatchQueue.main.asyncAfter(deadline: .now() + afterDelay) { [weak self] in
            guard let self = self else { return }
            // Edge-case: Dismiss `UpdateViewController` if presented, this can occur if `complete` is called before `UpdateViewController` is popped when we remove the last payment method via the `UpdateViewController`
            _ = self.updateViewController?.bottomSheetController?.popContentViewController()

            var latestPaymentMethods = self.paymentMethods
            // Move selected payment method to the front of `latestPaymentMethods`
            if let selectedPaymentMethod = self.selectedPaymentMethod {
                latestPaymentMethods.remove(selectedPaymentMethod)
                latestPaymentMethods.insert(selectedPaymentMethod, at: 0)
            }
            self.delegate?.didComplete(
                viewController: self,
                with: self.selectedPaymentMethod,
                latestPaymentMethods: latestPaymentMethods,
                didTapToDismiss: didTapToDismiss,
                defaultPaymentMethod: defaultPaymentMethod
            )
        }
    }
}

// MARK: - BottomSheetContentViewController
extension VerticalSavedPaymentMethodsViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        return true
    }

    func didTapOrSwipeToDismiss() {
        complete(didTapToDismiss: true)
    }

    var requiresFullScreen: Bool {
        return false
    }
}

// MARK: - SheetNavigationBarDelegate
extension VerticalSavedPaymentMethodsViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        // 'back' closed used in:
        //  Embedded
        complete()
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // 'back' style used in:
        //  PS.Complete & Vertical
        //  PS.FC & Vertical
        complete()
    }
}

// MARK: - PaymentMethodRowButtonDelegate
extension VerticalSavedPaymentMethodsViewController: SavedPaymentMethodRowButtonDelegate {

    func didSelectButton(_ button: SavedPaymentMethodRowButton, with paymentMethod: STPPaymentMethod) {
        analyticsHelper.logSavedPMScreenOptionSelected(option: .saved(paymentMethod: paymentMethod))
        if !elementsSession.paymentMethodSetAsDefaultForPaymentSheet {
            // Set local storage default
            CustomerPaymentOption.setDefaultPaymentMethod(
                .stripeId(paymentMethod.stripeId),
                forCustomer: configuration.customer?.id
            )
        }

        // Deselect previous button
        paymentMethodRows.first { $0 != button && $0.isSelected }?.state = .unselected

        // Disable interaction to prevent double selecting or entering edit mode since we will be dismissing soon
        self.view.isUserInteractionEnabled = false
        self.navigationBar.isUserInteractionEnabled = false

        self.complete()
    }

    func didSelectUpdateButton(_ button: SavedPaymentMethodRowButton, with paymentMethod: STPPaymentMethod) {
        let updateConfig = UpdatePaymentMethodViewController.Configuration(paymentMethod: paymentMethod,
                                                                           appearance: configuration.appearance,
                                                                           billingDetailsCollectionConfiguration: configuration.billingDetailsCollectionConfiguration,
                                                                           hostedSurface: .paymentSheet,
                                                                           cardBrandFilter: configuration.cardBrandFilter,
                                                                           canRemove: canRemovePaymentMethods,
                                                                           canUpdate: paymentMethodUpdate,
                                                                           isCBCEligible: paymentMethod.isCoBrandedCard && isCBCEligible,
                                                                           allowsSetAsDefaultPM: paymentMethodSetAsDefault,
                                                                           isDefault: isDefaultPaymentMethod(paymentMethodId: paymentMethod.stripeId))
        let updateViewController = UpdatePaymentMethodViewController(removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage,
                                                                     isTestMode: configuration.apiClient.isTestmode,
                                                                     configuration: updateConfig)
        updateViewController.delegate = self
        self.updateViewController = updateViewController
        self.bottomSheetController?.pushContentViewController(updateViewController)
    }
}

// MARK: - UpdatePaymentMethodViewControllerDelegate
extension VerticalSavedPaymentMethodsViewController: UpdatePaymentMethodViewControllerDelegate {
    func didRemove(viewController: UpdatePaymentMethodViewController, paymentMethod: STPPaymentMethod) {
        // if it's the default pm, unset the default
        if isDefaultPaymentMethod(paymentMethodId: paymentMethod.stripeId) {
            defaultPaymentMethod = nil
        }
        // if it's the last saved pm, there's some animation jank from trying to quickly dismiss the update pm screen and the manage screen, so we wait until the update pm screen is dismissed, animate the payment method fading, and return to the main screen
        if paymentMethodRows.count == 1 {
            _ = viewController.bottomSheetController?.popContentViewController {
                self.remove(paymentMethod: paymentMethod)
            }
        } else {
            remove(paymentMethod: paymentMethod)
            _ = viewController.bottomSheetController?.popContentViewController()
        }
    }

    func didUpdate(viewController: UpdatePaymentMethodViewController,
                   paymentMethod: STPPaymentMethod) async -> UpdatePaymentMethodResult
    {
        var errors: [Error] = []

        // Perform update if needed
        if let updateParams = viewController.updateParams,
           case .card(let paymentMethodCardParams, let billingDetails) = updateParams {
            let updateParams = STPPaymentMethodUpdateParams(card: paymentMethodCardParams, billingDetails: billingDetails)
            let hasOnlyChangedCardBrand = viewController.hasOnlyChangedCardBrand(originalPaymentMethod: paymentMethod,
                                                                                 updatedPaymentMethodCardParams: paymentMethodCardParams,
                                                                                 updatedBillingDetailsParams: billingDetails)
            if case .failure(let error) = await updateCard(paymentMethod: paymentMethod,
                                                           updateParams: updateParams,
                                                           hasOnlyChangedCardBrand: hasOnlyChangedCardBrand) {
                errors.append(error)
            }
        }

        // Update default payment method if needed
        if viewController.shouldSetAsDefault {
            if case .failure(let error) = await updateDefault(paymentMethod: paymentMethod) {
                errors.append(error)
            }
        }

        guard errors.isEmpty else {
            return .failure(errors)
        }

        _ = viewController.bottomSheetController?.popContentViewController()
        return .success
    }

    private func updateCard(paymentMethod: STPPaymentMethod, updateParams: STPPaymentMethodUpdateParams, hasOnlyChangedCardBrand: Bool) async -> Result<Void, Error> {
        do {
            // Update the payment method
            let updatedPaymentMethod = try await savedPaymentMethodManager.update(paymentMethod: paymentMethod, with: updateParams)

            replace(paymentMethod: paymentMethod, with: updatedPaymentMethod)
            return .success(())
        } catch {
            return hasOnlyChangedCardBrand ? .failure(NSError.stp_cardBrandNotUpdatedError()) : .failure(NSError.stp_genericErrorOccurredError())
        }
    }

    private func updateDefault(paymentMethod: STPPaymentMethod) async -> Result<Void, Error> {
        do {
            let previousDefaultPaymentMethod = defaultPaymentMethod
            _ = try await savedPaymentMethodManager.setAsDefaultPaymentMethod(defaultPaymentMethodId: paymentMethod.stripeId)
            defaultPaymentMethod = paymentMethod
            // we just set a new default, so we replace it to add the badge and select it
            replace(paymentMethod: paymentMethod, with: paymentMethod, selectedState: .selected)
            // if there was a previously selected payment method, replace it to deselect it and remove the badge if it was default
            if let previousSelectedPaymentMethod, previousSelectedPaymentMethod != defaultPaymentMethod {
                replace(paymentMethod: previousSelectedPaymentMethod, with: previousSelectedPaymentMethod, selectedState: .unselected)
            }
            // if there was a previous default payment method that wasn't previously selected, replace it to remove the badge
            if let previousDefaultPaymentMethod, previousDefaultPaymentMethod != previousSelectedPaymentMethod {
                replace(paymentMethod: previousDefaultPaymentMethod, with: previousDefaultPaymentMethod)
            }
            return .success(())
        } catch {
            return .failure(NSError.stp_defaultPaymentMethodNotUpdatedError())
        }
    }

    func shouldCloseSheet(_: UpdatePaymentMethodViewController) {
        complete(didTapToDismiss: true)
    }

    private func replace(paymentMethod: STPPaymentMethod, with updatedPaymentMethod: STPPaymentMethod, selectedState: SavedPaymentMethodRowButton.State? = nil) {
        guard let oldButton = paymentMethodRows.first(where: { $0.paymentMethod.stripeId == paymentMethod.stripeId }),
              let oldButtonModelIndex = paymentMethodRows.firstIndex(of: oldButton),
              let oldButtonViewIndex = stackView.arrangedSubviews.firstIndex(of: oldButton) else {
            stpAssertionFailure("Unable to retrieve the original button/payment method for replacement.")
            return
        }

        // Create the new button
        let isDefaultPaymentMethod = isDefaultPaymentMethod(paymentMethodId: updatedPaymentMethod.stripeId)
        let newButton = SavedPaymentMethodRowButton(paymentMethod: updatedPaymentMethod,
                                                    appearance: configuration.appearance,
                                                    showDefaultPMBadge: isDefaultPaymentMethod,
                                                    previousSelectedState: selectedState ?? oldButton.previousSelectedState,
                                                    currentState: oldButton.state)

        newButton.delegate = self

        // Replace the old button with the new button in the model
        paymentMethodRows[oldButtonModelIndex] = newButton

        // Replace the old button with the new button in the stack view
        oldButton.removeFromSuperview()
        stackView.insertArrangedSubview(newButton, at: oldButtonViewIndex)
    }

}
