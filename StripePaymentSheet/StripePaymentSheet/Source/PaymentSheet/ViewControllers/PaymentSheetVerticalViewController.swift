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
            savedPaymentMethod: loadResult.savedPaymentMethods.first,
            paymentMethodTypes: paymentMethodTypes,
            shouldShowApplePay: loadResult.isApplePayEnabled && isFlowController,
            shouldShowLink: loadResult.isLinkEnabled && walletHeaderView == nil,
            appearance: configuration.appearance,
            delegate: self
        )
    }()

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
        let headerView = VerticalHeaderView()
        headerView.set(text: .Localized.select_payment_method)
        headerView.isHidden = walletHeaderView != nil // Only show this header view if the wallet header view is empty
        return headerView
    }()

    // MARK: - Initializers

    init(configuration: PaymentSheet.Configuration, loadResult: PaymentSheetLoader.LoadResult, isFlowController: Bool) {
        // TODO: Deal with previousPaymentOption
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

    // MARK: - Helpers

    // TOOD(porter) Remove/rename
    @objc func presentManageScreen() {
        let vc = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: selectedPaymentOption?.savedPaymentMethod,
            paymentMethods: savedPaymentMethods,
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

extension PaymentSheetVerticalViewController: VerticalSavedPaymentMethodsViewControllerDelegate {
    func didComplete(viewController: VerticalSavedPaymentMethodsViewController,
                     with selectedPaymentMethod: STPPaymentMethod?,
                     latestPaymentMethods: [STPPaymentMethod]) {
        // TODO
        print("Selected payment method with id: \(String(describing: selectedPaymentMethod?.stripeId))")
        // Update our list of saved payment methods to be the latest from the manage screen incase of updates/removals
        savedPaymentMethods = latestPaymentMethods
        _ = viewController.bottomSheetController?.popContentViewController()
        // TODO update selected payment method with `selectedPaymentMethod`
    }
}

extension PaymentSheetVerticalViewController: VerticalPaymentMethodListViewControllerDelegate {
    func didTapPaymentMethod(_ selection: VerticalPaymentMethodListSelection) -> Bool {
#if !canImport(CompositorServices)
        UISelectionFeedbackGenerator().selectionChanged()
#endif
        switch selection {
        case .applePay, .link:
            return true
        case let .new(paymentMethodType: paymentMethodType):
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
        case .saved:
            // TODO(porter) Look for taps on the "view more" button
            presentManageScreen()
            return true
        }
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
        headerView.set(text: .Localized.select_payment_method)
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

extension PaymentSheetVerticalViewController: WalletHeaderViewDelegate {
    func walletHeaderViewApplePayButtonTapped(_ header: PaymentSheetViewController.WalletHeaderView) {
        // TODO
    }

    func walletHeaderViewPayWithLinkTapped(_ header: PaymentSheetViewController.WalletHeaderView) {
        // TODO
    }
}
