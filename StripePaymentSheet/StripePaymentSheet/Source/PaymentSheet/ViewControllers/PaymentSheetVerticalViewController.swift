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
    enum Error: Swift.Error {
        case missingPaymentMethodFormViewController
    }
    var selectedPaymentOption: PaymentSheet.PaymentOption? {
        // If we're showing the list, use its selection:
        if let paymentMethodListViewController, children.contains(paymentMethodListViewController) {
            switch paymentMethodListViewController.currentSelection {
            case nil:
                return nil
            case .applePay:
                return .applePay
            case .link:
                return .link(option: .wallet)
            case .new(paymentMethodType: let paymentMethodType):
                return .new(confirmParams: IntentConfirmParams(type: paymentMethodType))
            case .saved(paymentMethod: let paymentMethod):
                // TODO: Handle confirmParams - look at SavedPaymentOptionsViewController.selectedPaymentOptionIntentConfirmParams & CVC
                return .saved(paymentMethod: paymentMethod, confirmParams: nil)
            }
        } else {
            // Otherwise, we must be showing the form - use its payment option
            guard let paymentMethodFormViewController else {
                stpAssertionFailure("Expected paymentMethodFormViewController")
                let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError, error: Error.missingPaymentMethodFormViewController)
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                return nil
            }
            return paymentMethodFormViewController.paymentOption

        }
    }
    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType?
    let loadResult: PaymentSheetLoader.LoadResult
    let paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    let configuration: PaymentSheet.Configuration
    var intent: Intent {
        return loadResult.intent
    }
    var error: Swift.Error?
    private var savedPaymentMethods: [STPPaymentMethod]
    let isFlowController: Bool
    private var previousPaymentOption: PaymentOption?
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

    var paymentMethodListViewController: VerticalPaymentMethodListViewController?
    var paymentMethodFormViewController: PaymentMethodFormViewController?

    lazy var paymentContainerView: DynamicHeightContainerView = {
        return DynamicHeightContainerView()
    }()

    lazy var walletHeaderView: PaymentSheetViewController.WalletHeaderView? = {
        var walletOptions: PaymentSheetViewController.WalletHeaderView.WalletOptions = []

        // Offer Apple Pay in wallet if enabled and not in flow controller
        if loadResult.isApplePayEnabled, !isFlowController {
            walletOptions.insert(.applePay)
        }

        // Offer Link in wallet if we are not in flow controller or if we are in flow controller and Apple Pay is disabled
        if (!isFlowController && loadResult.isLinkEnabled) || (isFlowController && !loadResult.isApplePayEnabled && loadResult.isLinkEnabled) {
            walletOptions.insert(.link)
        }

        // If no wallet options available return nil
        guard !walletOptions.isEmpty else { return nil }

        let header = PaymentSheetViewController.WalletHeaderView(
            options: walletOptions,
            appearance: configuration.appearance,
            applePayButtonType: configuration.applePay?.buttonType ?? .plain,
            isPaymentIntent: intent.isPaymentIntent,
            delegate: self
        )
        return header
    }()

    lazy var headerView: VerticalHeaderView = {
        let headerView = VerticalHeaderView(text: .Localized.select_payment_method, appearance: configuration.appearance)
        headerView.isHidden = walletHeaderView != nil // Only show this header view if the wallet header view is empty
        return headerView
    }()

    var savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType? {
        return RowButton.RightAccessoryButton.getAccessoryButtonType(
            savedPaymentMethodsCount: savedPaymentMethods.count,
            isFirstCardCoBranded: savedPaymentMethods.first?.isCoBrandedCard ?? false,
            isCBCEligible: loadResult.intent.cardBrandChoiceEligible,
            allowsRemovalOfLastSavedPaymentMethod: configuration.allowsRemovalOfLastSavedPaymentMethod,
            allowsPaymentMethodRemoval: loadResult.intent.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()
        )
    }

    // MARK: - Initializers

    init(configuration: PaymentSheet.Configuration, loadResult: PaymentSheetLoader.LoadResult, isFlowController: Bool, previousPaymentOption: PaymentOption? = nil) {
        self.loadResult = loadResult
        self.configuration = configuration
        self.previousPaymentOption = previousPaymentOption
        self.isFlowController = isFlowController
        self.savedPaymentMethods = loadResult.savedPaymentMethods
        self.paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: loadResult.intent,
            configuration: configuration,
            logAvailability: false
        )
        super.init(nibName: nil, bundle: nil)

        regenerateUI()
        // Only use the previous customer input for the first form shown
        self.previousPaymentOption = nil
    }

    /// Regenerates the main content - either the PM list or the PM form
    func regenerateUI(selection: VerticalPaymentMethodListSelection? = nil) {
        // Determine whether to show the form only or the payment method list
        if let paymentMethodListViewController {
            remove(childViewController: paymentMethodListViewController)
        }
        if let paymentMethodFormViewController {
            remove(childViewController: paymentMethodFormViewController)
        }
        let firstPaymentMethodType = paymentMethodTypes[0]
        let displayLinkInList = loadResult.isLinkEnabled && isFlowController
        let displayApplePayInList = loadResult.isApplePayEnabled && isFlowController
        if savedPaymentMethods.isEmpty && paymentMethodTypes.count == 1 && !displayLinkInList && !displayApplePayInList && shouldDisplayForm(for: firstPaymentMethodType) {
            // If we'd only show one PM in the vertical list and it collects user input, display the form instead of the payment method list.
            let formVC = makeFormVC(paymentMethodType: firstPaymentMethodType)
            self.paymentMethodFormViewController = formVC
            add(childViewController: formVC, containerView: paymentContainerView)
        } else {
            if case let .new(confirmParams: confirmParams) = previousPaymentOption,
               paymentMethodTypes.contains(confirmParams.paymentMethodType),
               shouldDisplayForm(for: confirmParams.paymentMethodType)
            {
                // If the previous customer input was for a PM form and it collects user input, display the form
                self.paymentMethodListViewController = makePaymentMethodListViewController(selection: selection)
                let formVC = makeFormVC(paymentMethodType: confirmParams.paymentMethodType)
                self.paymentMethodFormViewController = formVC
                add(childViewController: formVC, containerView: paymentContainerView)
                navigationBar.setStyle(.back(showAdditionalButton: false))
            } else {
                // Otherwise, show the list of PMs
                // Create the PM List VC
                // Determine the initial selection - either the previous payment option or the last VC's selection
                let paymentMethodListViewController = makePaymentMethodListViewController(selection: selection)
                self.paymentMethodListViewController = paymentMethodListViewController
                add(childViewController: paymentMethodListViewController, containerView: paymentContainerView)
            }
        }
    }

    func makePaymentMethodListViewController(selection: VerticalPaymentMethodListSelection?) -> VerticalPaymentMethodListViewController {
        let initialSelection: VerticalPaymentMethodListSelection? = {
            if let selection {
                return selection
            }
            
            switch previousPaymentOption {
            case .applePay:
                return .applePay
            case .link:
                return .link
            case .external(paymentMethod: let paymentMethod, billingDetails: _):
                return .new(paymentMethodType: .external(paymentMethod))
            case .saved(paymentMethod: let paymentMethod, confirmParams: _):
                return .saved(paymentMethod: paymentMethod)
            case .new(confirmParams: let confirmParams):
                if shouldDisplayForm(for: confirmParams.paymentMethodType) {
                    return nil
                } else {
                    return .new(paymentMethodType: confirmParams.paymentMethodType)
                }
            case nil:
                // If there's no previous customer input...
                if let paymentMethodListViewController, let lastSelection =  paymentMethodListViewController.currentSelection {
                    // ...use the previous paymentMethodListViewController's selection
                    if case let .saved(paymentMethod: paymentMethod) = lastSelection {
                        // If the previous selection was a saved PM, only use it if it still exists:
                        if savedPaymentMethods.map({ $0.stripeId }).contains(paymentMethod.stripeId) {
                            return lastSelection
                        }
                    } else {
                        return lastSelection
                    }
                }
                // Default to the first saved payment method, if any
                return savedPaymentMethods.first.map { .saved(paymentMethod: $0) }
            }
        }()
        return VerticalPaymentMethodListViewController(
            initialSelection: initialSelection,
            savedPaymentMethod: savedPaymentMethods.first,
            paymentMethodTypes: paymentMethodTypes,
            shouldShowApplePay: loadResult.isApplePayEnabled && isFlowController,
            shouldShowLink: loadResult.isLinkEnabled && walletHeaderView == nil,
            savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType,
            appearance: configuration.appearance,
            delegate: self
        )
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
        let views: [UIView] = [headerView, walletHeaderView, paymentContainerView].compactMap { $0 }
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.setCustomSpacing(24, after: headerView)
        if let walletHeaderView {
            stackView.setCustomSpacing(24, after: walletHeaderView)
        }

        view.addAndPinSubview(stackView, insets: .init(top: 0, leading: 0, bottom: PaymentSheetUI.defaultSheetMargins.bottom, trailing: 0))
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
                                                                canRemoveCard: configuration.allowsRemovalOfLastSavedPaymentMethod && loadResult.intent.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet(),
                                                                isTestMode: configuration.apiClient.isTestmode)
            updateViewController.delegate = self
            bottomSheetController?.pushContentViewController(updateViewController)
            return
        }

        let vc = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: selectedPaymentOption?.savedPaymentMethod,
            paymentMethods: savedPaymentMethods,
            paymentMethodRemove: loadResult.intent.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet(),
            isCBCEligible: loadResult.intent.cardBrandChoiceEligible
        )
        vc.delegate = self
        bottomSheetController?.pushContentViewController(vc)
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

// MARK: - VerticalSavedPaymentMethodsViewControllerDelegate

extension PaymentSheetVerticalViewController: VerticalSavedPaymentMethodsViewControllerDelegate {
    func didComplete(viewController: VerticalSavedPaymentMethodsViewController,
                     with selectedPaymentMethod: STPPaymentMethod?,
                     latestPaymentMethods: [STPPaymentMethod]) {
        // Update our list of saved payment methods to be the latest from the manage screen incase of updates/removals
        self.savedPaymentMethods = latestPaymentMethods
        var selection: VerticalPaymentMethodListSelection?
        if let selectedPaymentMethod {
            selection = .saved(paymentMethod: selectedPaymentMethod)
        }
        regenerateUI(selection: selection)

        _ = viewController.bottomSheetController?.popContentViewController()
    }
}

// MARK: - VerticalPaymentMethodListViewControllerDelegate

extension PaymentSheetVerticalViewController: VerticalPaymentMethodListViewControllerDelegate {
    func didTapPaymentMethod(_ selection: VerticalPaymentMethodListSelection) -> Bool {
#if !canImport(CompositorServices)
        UISelectionFeedbackGenerator().selectionChanged()
#endif
        switch selection {
        case .applePay, .link:
            return true
        case let .new(paymentMethodType: paymentMethodType):
            // Update the header view, hide wallet if needed and show header label if needed
            walletHeaderView?.isHidden = true
            headerView.isHidden = false
            if paymentMethodType == .stripe(.card) {
                let text = savedPaymentMethods.isEmpty ? String.Localized.add_card : String.Localized.add_new_card
                headerView.set(text: text)
            } else {
                headerView.update(with: paymentMethodType)
            }

            // If we can, reuse the existing payment method form so that the customer doesn't have to type their details in again
            if let currentPaymentMethodFormVC = paymentMethodFormViewController, paymentMethodType == currentPaymentMethodFormVC.paymentMethodType {
                // Switch the main content to the form
                switchContentIfNecessary(to: currentPaymentMethodFormVC, containerView: paymentContainerView)
                navigationBar.setStyle(.back(showAdditionalButton: false))
                // Return false so the payment method isn't selected in the list; this implicitly keeps the most recently selected payment method as selected.
                return false
            } else {
                // Otherwise, create the form and decide whether we should display it or not
                let pmFormVC = makeFormVC(paymentMethodType: paymentMethodType)
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
        case .saved:
            return true
        }
    }

    func didTapSavedPaymentMethodAccessoryButton() {
        presentManageScreen()
    }

    private func makeFormVC(paymentMethodType: PaymentSheet.PaymentMethodType) -> PaymentMethodFormViewController {
        let previousCustomerInput: IntentConfirmParams? = {
            if case let .new(confirmParams: confirmParams) = previousPaymentOption {
                return confirmParams
            } else {
                return nil
            }
        }()
        return PaymentMethodFormViewController(
            type: paymentMethodType,
            intent: intent,
            previousCustomerInput: previousCustomerInput,
            configuration: configuration,
            isLinkEnabled: false, // TODO: isLinkEnabled
            delegate: self
        )
    }

    private func shouldDisplayForm(for paymentMethodType: PaymentSheet.PaymentMethodType) -> Bool {
        return makeFormVC(paymentMethodType: paymentMethodType).form.collectsUserInput
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
        switchContentIfNecessary(to: paymentMethodListViewController!, containerView: paymentContainerView)
        navigationBar.setStyle(.close(showAdditionalButton: false))
        headerView.set(text: .Localized.select_payment_method)
        headerView.isHidden = walletHeaderView != nil
        walletHeaderView?.isHidden = walletHeaderView == nil
    }
}

// MARK: UpdateCardViewControllerDelegate
extension PaymentSheetVerticalViewController: UpdateCardViewControllerDelegate {
    func didRemove(viewController: UpdateCardViewController, paymentMethod: STPPaymentMethod) {
        guard let ephemeralKeySecret = configuration.customer?.ephemeralKeySecret else { return }

        // Detach the payment method from the customer
        let manager = SavedPaymentMethodManager(configuration: configuration)
        manager.detach(paymentMethod: paymentMethod, using: ephemeralKeySecret)

        // Update savedPaymentMethods
        self.savedPaymentMethods.removeAll(where: { $0.stripeId == paymentMethod.stripeId })

        // Update UI
        regenerateUI()
        _ = viewController.bottomSheetController?.popContentViewController()
    }

    func didUpdate(viewController: UpdateCardViewController, paymentMethod: STPPaymentMethod, updateParams: STPPaymentMethodUpdateParams) async throws {
        guard let ephemeralKeySecret = configuration.customer?.ephemeralKeySecret else { return }

        // Update the payment method
        let manager = SavedPaymentMethodManager(configuration: configuration)
        let updatedPaymentMethod = try await manager.update(paymentMethod: paymentMethod, with: updateParams, using: ephemeralKeySecret)

        // Update savedPaymentMethods
        if let row = self.savedPaymentMethods.firstIndex(where: { $0.stripeId == updatedPaymentMethod.stripeId }) {
            self.savedPaymentMethods[row] = updatedPaymentMethod
        }

        // Update UI
        regenerateUI()
        _ = viewController.bottomSheetController?.popContentViewController()
    }
}

extension PaymentSheetVerticalViewController: PaymentMethodFormViewControllerDelegate {
    func didUpdate(_ viewController: PaymentMethodFormViewController) {
        // TODO
    }

    func updateErrorLabel(for error: Swift.Error?) {
        // TODO
    }
}

extension PaymentSheetVerticalViewController: WalletHeaderViewDelegate {
    func walletHeaderViewApplePayButtonTapped(_ header: PaymentSheetViewController.WalletHeaderView) {
        // TODO
    }

    func walletHeaderViewPayWithLinkTapped(_ header: PaymentSheetViewController.WalletHeaderView) {
        // TODO
    }
}
