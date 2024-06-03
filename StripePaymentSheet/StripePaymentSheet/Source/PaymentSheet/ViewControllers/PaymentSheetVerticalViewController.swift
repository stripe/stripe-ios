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
    var lastVerticalSelection: VerticalPaymentMethodListSelection?
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
            savedPaymentMethodsCount: loadResult.savedPaymentMethods.count,
            isFirstCardCoBranded: loadResult.savedPaymentMethods.first?.isCoBrandedCard ?? false,
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

    func makeForm(paymentMethodType: PaymentSheet.PaymentMethodType) -> PaymentMethodElement {
        return PaymentSheetFormFactory(intent: intent, configuration: .paymentSheet(configuration), paymentMethod: paymentMethodType).make()
    }

    func updateUI() {
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
        let form = makeForm(paymentMethodType: firstPaymentMethodType)
        if paymentMethodListViewController.rowCount == 1 && form.collectsUserInput {
            let paymentMethodFormViewController = PaymentMethodFormViewController(type: firstPaymentMethodType, form: form)
            self.paymentMethodFormViewController = paymentMethodFormViewController
            add(childViewController: paymentMethodFormViewController, containerView: paymentContainerView)
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
        // Only update current selection if a selection was made
        if let selectedPaymentMethod {
            _ = didTapPaymentMethod(.saved(paymentMethod: selectedPaymentMethod))
        } else if case .saved = selectedPaymentOption {
            // Reset the selected payment option if we had previously selected a saved payment method
            selectedPaymentOption = nil
        }

        // Update our list of saved payment methods to be the latest from the manage screen incase of updates/removals
        self.savedPaymentMethods = latestPaymentMethods
        updateUI()
        _ = viewController.bottomSheetController?.popContentViewController()
    }
}

extension PaymentSheetVerticalViewController: VerticalPaymentMethodListViewControllerDelegate {
    func didTapPaymentMethod(_ selection: VerticalPaymentMethodListSelection) -> Bool {
        self.lastVerticalSelection = selection
#if !canImport(CompositorServices)
        UISelectionFeedbackGenerator().selectionChanged()
#endif
        switch selection {
        case .applePay, .link:
            return true
        case let .new(paymentMethodType: paymentMethodType):
            selectedPaymentOption = .new(confirmParams: .init(type: paymentMethodType))
            let form = makeForm(paymentMethodType: paymentMethodType)
            if form.collectsUserInput {
                // The payment method form collects user input, display it
                // 1. Create the PM form VC
                let paymentMethodFormVC: PaymentMethodFormViewController = {
                    if let currentPaymentMethodFormVC = paymentMethodFormViewController, paymentMethodType == currentPaymentMethodFormVC.paymentMethodType {
                        // Reuse the existing payment method form so that the customer doesn't have to type their details in again
                        return currentPaymentMethodFormVC
                    } else {
                        return PaymentMethodFormViewController(type: paymentMethodType, form: form)
                    }
                }()
                paymentMethodFormViewController = paymentMethodFormVC
                // 2. Switch the main content to the form
                switchContentIfNecessary(to: paymentMethodFormVC, containerView: paymentContainerView)
                navigationBar.setStyle(.back(showAdditionalButton: false))
                // 3. Return false so the payment method isn't selected in the list; this implicitly keeps the most recently selected payment method as selected.
                return false
            } else {
                // Otherwise, return true so the payment method appears selected in the list
                return true
            }
        case let .saved(paymentMethod: paymentMethod):
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
