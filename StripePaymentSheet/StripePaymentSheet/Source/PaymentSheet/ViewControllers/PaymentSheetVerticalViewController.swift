//
//  PaymentSheetVerticalViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/3/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

class PaymentSheetVerticalViewController: UIViewController, FlowControllerViewControllerProtocol, PaymentSheetViewControllerProtocol {
    var selectedPaymentOption: PaymentSheet.PaymentOption?

    var lastVerticalSelection: VerticalPaymentMethodListSelection? {
        switch selectedPaymentOption {
        case .applePay: // TODO(porter) Flesh out when these are selected from the wallet (technically not a vertical list selection)
            return .applePay
        case .saved(let paymentMethod, _):
            return .saved(paymentMethod: paymentMethod)
        case .new(let confirmParams):
            return .new(paymentMethodType: confirmParams.paymentMethodType)
        case .link: // TODO(porter) Flesh out when these are selected from the wallet (technically not a vertical list selection)
            return .link
        case .external(let paymentMethod, _):
            return .new(paymentMethodType: .external(paymentMethod))
        case nil:
            return nil
        }
    }
    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType?
    let loadResult: PaymentSheetLoader.LoadResult
    let paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    let configuration: PaymentSheet.Configuration
    var intent: Intent {
        return loadResult.intent
    }
    var error: Error?
    private var savedPaymentMethods: [STPPaymentMethod]
    let isFlowController: Bool
    weak var flowControllerDelegate: FlowControllerViewControllerDelegate?
    weak var paymentSheetDelegate: PaymentSheetViewControllerDelegate?

    // MARK: - UI properties

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(
            isTestMode: configuration.apiClient.isTestmode,
            appearance: configuration.appearance
        )
        navBar.delegate = self
        return navBar
    }()

    lazy var paymentMethodListViewController: VerticalPaymentMethodListViewController = {
        return VerticalPaymentMethodListViewController(
            currentSelection: lastVerticalSelection,
            savedPaymentMethod: loadResult.savedPaymentMethods.first,
            paymentMethodTypes: paymentMethodTypes,
            shouldShowApplePay: loadResult.isApplePayEnabled && isFlowController,
            shouldShowLink: loadResult.isLinkEnabled && isFlowController, // TODO: Edge case where we show Link as button in FC if Apple Pay not enabled
            rightAccessoryType: rightAccessoryType,
            appearance: configuration.appearance,
            delegate: self
        )
    }()

    var paymentMethodFormViewController: PaymentMethodFormViewController?

    lazy var paymentContainerView: DynamicHeightContainerView = {
        return DynamicHeightContainerView()
    }()

    var rightAccessoryType: RowButton.RightAccessoryButton.AccessoryType? {
        return RowButton.RightAccessoryButton.getAccessoryButtonType(
            savedPaymentMethodsCount: savedPaymentMethods.count,
            isFirstCardCoBranded: savedPaymentMethods.first?.isCoBrandedCard ?? false,
            isCBCEligible: loadResult.intent.cardBrandChoiceEligible,
            allowsRemovalOfLastSavedPaymentMethod: configuration.allowsRemovalOfLastSavedPaymentMethod,
            paymentMethodRemove: configuration.paymentMethodRemove
        )
    }

    // MARK: - Initializers

    init(configuration: PaymentSheet.Configuration, loadResult: PaymentSheetLoader.LoadResult, isFlowController: Bool) {
        // TODO: Deal with previousPaymentOption, default to first saved PM for now
        if let savedPaymentMethod = loadResult.savedPaymentMethods.first {
            self.selectedPaymentOption = .saved(paymentMethod: savedPaymentMethod, confirmParams: nil)
        }
        self.loadResult = loadResult
        self.configuration = configuration
        self.isFlowController = isFlowController
        self.savedPaymentMethods = loadResult.savedPaymentMethods
        self.paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: loadResult.intent,
            configuration: configuration,
            logAvailability: false
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background
        configuration.style.configure(self)

        // One stack view contains all our subviews
        let stackView = UIStackView(arrangedSubviews: [
            paymentContainerView,
        ])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical

        view.addAndPinSubview(stackView, insets: .init(top: 0, leading: 0, bottom: PaymentSheetUI.defaultSheetMargins.bottom, trailing: 0))

        updateUI()
    }

    // MARK: - Helpers

    @objc func presentManageScreen() {
        // Special case, only 1 card remaining but is co-branded, show update view controller
        if savedPaymentMethods.count == 1,
           let paymentMethod = savedPaymentMethods.first,
           paymentMethod.isCoBrandedCard,
           loadResult.intent.cardBrandChoiceEligible {
            let updateViewController = UpdateCardViewController(paymentMethod: paymentMethod,
                                                                removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage,
                                                                appearance: configuration.appearance,
                                                                hostedSurface: .paymentSheet,
                                                                canRemoveCard: configuration.allowsRemovalOfLastSavedPaymentMethod && configuration.paymentMethodRemove,
                                                                isTestMode: configuration.apiClient.isTestmode)
            updateViewController.delegate = self
            bottomSheetController?.pushContentViewController(updateViewController)
            return
        }

        let vc = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: selectedPaymentOption?.savedPaymentMethod,
            paymentMethods: savedPaymentMethods,
            isCBCEligible: loadResult.intent.cardBrandChoiceEligible
        )
        vc.delegate = self
        bottomSheetController?.pushContentViewController(vc)
    }

    func updateUI() {
        remove(childViewController: self.paymentMethodListViewController)
        if let paymentMethodFormViewController = self.paymentMethodFormViewController {
            remove(childViewController: paymentMethodFormViewController)
        }

        self.paymentMethodListViewController = VerticalPaymentMethodListViewController(
            currentSelection: lastVerticalSelection,
            savedPaymentMethod: selectedPaymentOption?.savedPaymentMethod ?? savedPaymentMethods.first,
            paymentMethodTypes: paymentMethodTypes,
            shouldShowApplePay: loadResult.isApplePayEnabled && isFlowController,
            shouldShowLink: loadResult.isLinkEnabled && isFlowController, // TODO: Edge case where we show Link as button in FC if Apple Pay not enabled
            rightAccessoryType: rightAccessoryType,
            appearance: configuration.appearance,
            delegate: self
        )

        // If we have only one row in the vertical list and it collects user input, display the form instead of the payment method list.
        let firstPaymentMethodType = paymentMethodTypes[0]
        // TODO: Handle offerSaveToLinkWhenSupported, previousCustomerInput, delegate
        let pmFormVC = PaymentMethodFormViewController(type: firstPaymentMethodType, intent: intent, previousCustomerInput: nil, configuration: configuration, isLinkEnabled: false, delegate: self)
        if paymentMethodListViewController.rowCount == 1 && pmFormVC.form.collectsUserInput {
            self.paymentMethodFormViewController = pmFormVC
            add(childViewController: pmFormVC, containerView: paymentContainerView)
        } else {
            add(childViewController: paymentMethodListViewController, containerView: paymentContainerView)
        }
    }
}

// MARK: - BottomSheetContentViewController
extension PaymentSheetVerticalViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        // TODO
        return true
    }

    func didTapOrSwipeToDismiss() {
        // TODO
        if isFlowController {
            flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: true)
        } else {
            paymentSheetDelegate?.paymentSheetViewControllerDidCancel(self)
        }
    }

    var requiresFullScreen: Bool {
        // TODO
        return false
    }

    func didFinishAnimatingHeight() {
        // no-op
    }
}

extension PaymentSheetVerticalViewController: VerticalSavedPaymentMethodsViewControllerDelegate {
    func didComplete(viewController: VerticalSavedPaymentMethodsViewController,
                     with selectedPaymentMethod: STPPaymentMethod?,
                     latestPaymentMethods: [STPPaymentMethod]) {
        // Update our list of saved payment methods to be the latest from the manage screen incase of updates/removals
        self.savedPaymentMethods = latestPaymentMethods

        // If a selection was made update the selection
        if let selectedPaymentMethod {
            self.selectedPaymentOption = .saved(paymentMethod: selectedPaymentMethod, confirmParams: nil)
        } else if case .saved = selectedPaymentOption, let firstSavedPaymentMethod = latestPaymentMethods.first {
            // If no selection was made, default to the first saved payment method if we were selecting a saved payment method
            self.selectedPaymentOption = .saved(paymentMethod: firstSavedPaymentMethod, confirmParams: nil)
        } else if case .saved = selectedPaymentOption {
            // If we had a saved payment method selected and we did not make a selection and no saved payment methods remain, reset to nil
            self.selectedPaymentOption = nil
        }

        updateUI()
        _ = viewController.bottomSheetController?.popContentViewController()
    }
}

extension PaymentSheetVerticalViewController: VerticalPaymentMethodListViewControllerDelegate {
    func didTapPaymentMethod(_ selection: VerticalPaymentMethodListSelection) -> Bool {
#if !canImport(CompositorServices)
        UISelectionFeedbackGenerator().selectionChanged()
#endif
        switch selection {
        case .applePay, .link:
            // TODO Set payment option
            return true
        case let .new(paymentMethodType: paymentMethodType):
            selectedPaymentOption = .new(confirmParams: .init(type: paymentMethodType))
            // If we can, reuse the existing payment method form so that the customer doesn't have to type their details in again
            if let currentPaymentMethodFormVC = paymentMethodFormViewController, paymentMethodType == currentPaymentMethodFormVC.paymentMethodType {
                // Switch the main content to the form
                switchContentIfNecessary(to: currentPaymentMethodFormVC, containerView: paymentContainerView)
                navigationBar.setStyle(.back(showAdditionalButton: false))
                // Return false so the payment method isn't selected in the list; this implicitly keeps the most recently selected payment method as selected.
                return false
            } else {
                // Otherwise, create the form and decide whether we should display it or not
                let pmFormVC = PaymentMethodFormViewController(type: paymentMethodType, intent: intent, previousCustomerInput: nil, configuration: configuration, isLinkEnabled: false, delegate: self)

                if pmFormVC.form.collectsUserInput {
                    // The payment method form collects user input, display it
                    self.paymentMethodFormViewController = pmFormVC
                    switchContentIfNecessary(to: pmFormVC, containerView: paymentContainerView)
                    navigationBar.setStyle(.back(showAdditionalButton: false))
                    return false
                } else {
                    // Otherwise, return true so the payment method appears selected in the list
                   return true
                }
            }
        case .saved(let paymentMethod):
            selectedPaymentOption = .saved(paymentMethod: paymentMethod, confirmParams: nil)
            return true
        }
    }

    func didTapSavedPaymentMethodAccessoryButton() {
        presentManageScreen()
    }
}

extension PaymentSheetVerticalViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        // TODO:
        if isFlowController {
            flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: true)
        } else {
            paymentSheetDelegate?.paymentSheetViewControllerDidCancel(self)
        }
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // Hide the keyboard if it appeared and switch back to the vertical list
        view.endEditing(true)
        switchContentIfNecessary(to: paymentMethodListViewController, containerView: paymentContainerView)
        navigationBar.setStyle(.close(showAdditionalButton: false))
    }
}

// MARK: UpdateCardViewControllerDelegate
extension PaymentSheetVerticalViewController: UpdateCardViewControllerDelegate {
    func didRemove(viewController: UpdateCardViewController, paymentMethod: STPPaymentMethod) {
        guard let ephemeralKeySecret = configuration.customer?.ephemeralKeySecret else { return }

        // Detach the payment method from the customer
        let manager = SavedPaymentMethodManager(configuration: configuration)
        manager.detach(paymentMethod: paymentMethod, using: ephemeralKeySecret)

        // Update our model
        // If we removed the selected option, reset to nil
        if self.selectedPaymentOption?.savedPaymentMethod?.stripeId == paymentMethod.stripeId {
            self.selectedPaymentOption = nil
        }
        self.savedPaymentMethods.removeAll(where: { $0.stripeId == paymentMethod.stripeId })

        // Update UI
        updateUI()
        _ = viewController.bottomSheetController?.popContentViewController()
    }

    func didUpdate(viewController: UpdateCardViewController, paymentMethod: STPPaymentMethod, updateParams: STPPaymentMethodUpdateParams) async throws {
        guard let ephemeralKeySecret = configuration.customer?.ephemeralKeySecret else { return }

        // Update the payment method
        let manager = SavedPaymentMethodManager(configuration: configuration)
        let updatedPaymentMethod = try await manager.update(paymentMethod: paymentMethod, with: updateParams, using: ephemeralKeySecret)

        // Update our model
        // If we updated the currently selected payment option, update it
        if self.selectedPaymentOption?.savedPaymentMethod?.stripeId == updatedPaymentMethod.stripeId {
            self.selectedPaymentOption = .saved(paymentMethod: updatedPaymentMethod, confirmParams: nil)
        }
        if let row = self.savedPaymentMethods.firstIndex(where: { $0.stripeId == updatedPaymentMethod.stripeId }) {
            self.savedPaymentMethods[row] = updatedPaymentMethod
        }

        // Update UI
        updateUI()
        _ = viewController.bottomSheetController?.popContentViewController()
    }
}

extension PaymentSheetVerticalViewController: PaymentMethodFormViewControllerDelegate {
    func didUpdate(_ viewController: PaymentMethodFormViewController) {
        // TODO
    }

    func updateErrorLabel(for error: (any Error)?) {
        // TODO
    }
}
